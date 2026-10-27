// commitlint configuration.
//
// This file replaces the former .commitlintrc.yml. It is JavaScript rather than YAML
// because the breaking-change-footer-intact rule below needs code. Everything else
// is unchanged.
//
// See: https://commitlint.js.org/reference/rules.html
//
// Each rule is a name and a configuration array:
//
// * Severity [0..2]: 0 disables the rule, 1 warns when violated, 2 errors when
//   violated
// * Applicability [always|never]: never inverts the rule
// * Value: value to use for this rule (if applicable)
//
// Run `npx commitlint --print-config` to see the current setting for all rules.

// A BREAKING CHANGE footer, as release-please will publish it.
//
// release-please parses commit messages with @conventional-commits/parser, which
// follows the Conventional Commits grammar strictly. A continuation line of a footer
// that begins with a word followed by ":" or by " #" is read as the start of a new
// footer when every line after it through the end of the paragraph reads that way
// too; a later line of prose restores the paragraph. "Git::AuthorInfo is ..." and
// "global: true ..." both start a new footer this way. commitlint's own parser is
// lenient and keeps every line, so it cannot see the problem. The 6.0.0 changelog
// shipped five breaking-change entries cut off mid-sentence because of this.
//
// This rule parses the message with the same parser release-please uses, renders each
// BREAKING CHANGE note the way release-please renders it for the changelog, and
// requires that every BREAKING CHANGE paragraph in the message comes out as the
// author wrote it. The parser is loaded when the rule first meets a BREAKING CHANGE
// paragraph, so a clone that has not run `npm install` since the parser became a
// devDependency can still make every other kind of commit. The version range of
// @conventional-commits/parser in package.json matches the range release-please
// depends on; keep them in step.

// Lines that git removes before recording an editor-made commit: the comment block
// git appends below the message and, with `git commit -v`, the scissors line and the
// diff below it. commitlint strips these for its own parse but hands this rule the
// raw file, so the rule strips them too. A `#### heading` line of release-please
// extended context is dropped along with them, as git itself would drop it from an
// editor-made commit.
const SCISSORS_LINE = /^# -+ >8 -+$/;

const stripGitComments = (raw) => {
  const kept = [];
  for (const line of raw.split(/\r?\n/)) {
    if (SCISSORS_LINE.test(line)) break;
    if (line.startsWith('#')) continue;
    kept.push(line);
  }
  return kept.join('\n');
};

// Lines of a BREAKING CHANGE paragraph: the BREAKING CHANGE line and the lines after
// it, up to a blank line, the end of the message, or a well-known footer token. A line
// that starts with any other "word:" is treated as part of the paragraph, which is how
// the author meant it and how the mismatch is detected.
const KNOWN_FOOTER_TOKEN = /^(BREAKING[ -]CHANGE|Closes|Fixes|Resolves|Refs|Release-As|Reviewed-by|Signed-off-by|Co-authored-by)(: | #)/i;
const BREAKING_CHANGE_LINE = /^BREAKING[ -]CHANGE:\s*(.*)$/;

const breakingChangeParagraphs = (message) => {
  const lines = message.split('\n');
  const paragraphs = [];
  for (let i = 0; i < lines.length; i += 1) {
    const match = lines[i].match(BREAKING_CHANGE_LINE);
    if (!match) continue;
    const text = [match[1].trim()];
    for (let j = i + 1; j < lines.length; j += 1) {
      if (lines[j].trim() === '' || KNOWN_FOOTER_TOKEN.test(lines[j])) break;
      text.push(lines[j]);
      i = j;
    }
    paragraphs.push(text.join('\n'));
  }
  return paragraphs;
};

// The rest of release-please's handling of a commit message, ported from
// src/commit.ts in googleapis/release-please (sanitizeBodyScopes, parseCommits,
// postProcessCommits, and hasExtendedContext). Keep in step with upstream.

// A body line that starts at column 0 with `token(` and reaches another `(` or the
// end of the line before a closing `)` makes the parser throw. release-please prefixes
// such lines with a space and parses again.
const UNTERMINATED_SCOPE_LINE = /^[^\s:!()]+\([^()\r\n]*(?:\(|\r?$)/;

const sanitizeBodyScopes = (message) => {
  const lines = message.split('\n');
  for (let i = 1; i < lines.length; i += 1) {
    if (UNTERMINATED_SCOPE_LINE.test(lines[i])) lines[i] = ` ${lines[i]}`;
  }
  return lines.join('\n');
};

const parseLikeReleasePlease = (parser, message) => {
  try {
    return parser(message);
  } catch (error) {
    const sanitized = sanitizeBodyScopes(message);
    if (sanitized === message) throw error;
    return parser(sanitized);
  }
};

// A line after the first that is a fourth-level heading or a bullet starts extended
// context, which release-please indents under the entry.
const hasExtendedContext = (line) => /^#### |^[*-] /.test(line);

// How release-please renders a note for the changelog: lines joined by spaces, with
// extended context indented on lines of its own.
const renderNote = (text) => {
  let rendered = '';
  let extendedContext = false;
  const chunks = text.split(/\r?\n/);
  for (let i = 0; i < chunks.length; i += 1) {
    const chunk = chunks[i];
    if (i > 0 && hasExtendedContext(chunk) && !extendedContext) {
      rendered = `${rendered.trim()}\n`;
      extendedContext = true;
    }
    if (chunk === '') break;
    if (extendedContext) {
      rendered += `    ${chunk}\n`;
    } else {
      rendered += `${chunk} `;
    }
  }
  return rendered.trim();
};

const releasePleaseEntries = ({ parser, toConventionalChangelogFormat }, message) => {
  const commit = toConventionalChangelogFormat(parseLikeReleasePlease(parser, message));
  const entries = commit.notes
    .filter((note) => note.title === 'BREAKING CHANGE')
    .map((note) => renderNote(note.text));
  const bodyMatch = commit.body?.match(/BREAKING-CHANGE:\s*(.*)/);
  if (bodyMatch && bodyMatch[1]) {
    if (entries.length > 0) {
      entries[0] += `\n${bodyMatch[1].trim()}`;
    } else {
      entries.push(bodyMatch[1].trim());
    }
  }
  return entries;
};

const loadParser = async () => {
  try {
    return await import('@conventional-commits/parser');
  } catch (error) {
    if (error.code !== 'ERR_MODULE_NOT_FOUND') throw error;
    return null;
  }
};

const PARSER_MISSING =
  '@conventional-commits/parser is not installed, so this BREAKING CHANGE footer ' +
  'cannot be checked against release-please. Run `npm install` in the project root ' +
  '(bin/setup does this) and commit again.';

const ABSORBED_ADVICE =
  'The blank line after the paragraph does not end the footer for release-please, ' +
  'so the text after it is joined into the entry. Move that text above the ' +
  'BREAKING CHANGE footer, or make it a footer of its own.';

const TRUNCATED_ADVICE =
  'A continuation line that starts with a word followed by ":" or " #" is read as a ' +
  'new footer when every line after it through the end of the paragraph reads that ' +
  'way too; a later line of prose restores the paragraph. Rewrap the paragraph so no ' +
  'line starts that way, or end it with a line of prose. If that line is a footer of ' +
  'its own, separate it from the paragraph with a blank line.';

const OTHER_ADVICE =
  'Compare the two and rewrap the paragraph so release-please reads it as written.';

const adviceFor = (published, expected) => {
  if (published === undefined) return TRUNCATED_ADVICE;
  if (published.startsWith(expected)) return ABSORBED_ADVICE;
  if (expected.startsWith(published)) return TRUNCATED_ADVICE;
  return OTHER_ADVICE;
};

const indent = (text) => text.replace(/^/gm, '  ');

const breakingChangeFooterIntact = async (parsed) => {
  const message = stripGitComments(parsed.raw ?? '');
  const expected = breakingChangeParagraphs(message).map(renderNote);
  if (expected.length === 0) return [true];

  const parserModule = await loadParser();
  if (parserModule === null) return [false, PARSER_MISSING];

  let published;
  try {
    published = releasePleaseEntries(parserModule, message);
  } catch (error) {
    return [false, `release-please cannot parse this commit message: ${error.message}`];
  }

  const missing = expected.filter((entry) => !published.includes(entry));
  if (missing.length === 0) return [true];

  const [entry] = missing;
  const closest =
    published.find((candidate) => candidate.startsWith(entry) || entry.startsWith(candidate)) ??
    published[0];
  return [
    false,
    'release-please would publish this BREAKING CHANGE entry as\n' +
      `${indent(closest ?? '(nothing)')}\n` +
      'instead of\n' +
      `${indent(entry)}\n` +
      adviceFor(closest, entry),
  ];
};

export default {
  extends: ['@commitlint/config-conventional'],

  plugins: [
    {
      rules: {
        'breaking-change-footer-intact': breakingChangeFooterIntact,
      },
    },
  ],

  rules: {
    'header-max-length': [2, 'always', 100], // Header can not exceed 100 chars

    'type-case': [2, 'always', 'lower-case'], // Type must be lower case
    'type-empty': [2, 'never'], // Type must not be empty

    // Supported conventional commit types
    'type-enum': [
      2,
      'always',
      ['build', 'ci', 'chore', 'docs', 'feat', 'fix', 'perf', 'refactor', 'revert', 'style', 'test'],
    ],

    'scope-case': [2, 'always', 'lower-case'], // Scope must be lower case

    // Error if subject is one of these cases (encourages lower-case)
    'subject-case': [2, 'never', ['sentence-case', 'start-case', 'pascal-case', 'upper-case']],
    'subject-empty': [2, 'never'], // Subject must not be empty
    'subject-full-stop': [2, 'never', '.'], // Subject must not end with a period

    'body-leading-blank': [2, 'always'], // Body must have a blank line before it
    'body-max-line-length': [2, 'always', 100], // Body lines can not exceed 100 chars

    'footer-leading-blank': [2, 'always'], // Footer must have a blank line before it
    'footer-max-line-length': [2, 'always', 100], // Footer lines can not exceed 100 chars

    // Every BREAKING CHANGE footer must come out of release-please as written
    'breaking-change-footer-intact': [2, 'always'],
  },
};
