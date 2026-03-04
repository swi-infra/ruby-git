# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::CommandLine do
  it 'is a module (not a class)' do
    expect(described_class).to be_a(Module)
    expect(described_class).not_to be_a(Class)
  end

  it 'exposes Base' do
    expect(Git::CommandLine::Base).to be_a(Class)
  end

  it 'exposes Capturing' do
    expect(Git::CommandLine::Capturing).to be_a(Class)
  end

  it 'exposes Streaming' do
    expect(Git::CommandLine::Streaming).to be_a(Class)
  end

  it 'exposes Result' do
    expect(Git::CommandLine::Result).to be_a(Class)
  end
end
