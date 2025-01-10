# frozen_string_literal: true

require "action_view/base"

describe Keynote::Inline do
  let(:presenter) { InlineUserPresenter.new(:view) }

  def clean_whitespace(str)
    str.gsub(/\s/, "")
  end

  before do
    Keynote::Inline::Cache.reset
  end

  it "renders a template" do
    expect(presenter.simple_template.strip).to eq("Here's some math: 4")
  end

  it "sees instance variables from the presenter" do
    expect(presenter.ivars.strip).to eq("Hello world!")
  end

  it "sees locals passed in as a hash" do
    expect(presenter.locals_from_hash.strip).to eq("Local H")
  end

  it "sees locals passed in as a binding" do
    expect(presenter.locals_from_binding.strip).to eq("Local H")
  end

  it "calls other methods from the same object" do
    expect(presenter.method_calls.strip.squeeze(" ")).to eq("Local H\nLocal H")
  end

  it "handles errors relatively gracefully" do
    begin
      presenter.error_handling
    rescue => e
    end

    expect(e).to be_a(ActionView::Template::Error)

    if e.respond_to?(:original_exception)
      expect(e.original_exception).to be_a(RuntimeError)
      expect(e.original_exception.message).to eq("UH OH")
    else
      expect(e.cause).to be_a(RuntimeError)
      expect(e.cause.message).to eq("UH OH")
    end
  end

  it "removes leading indentation" do
    expect(presenter.fix_indentation).to eq(
      "<div class=\"indented_slightly\">2 times 3 times 4 times </div>"
    )
  end

  it "escapes HTML by default" do
    unescaped = "<script>alert(1);</script>"
    escaped = unescaped.gsub("<", "&lt;").gsub(">", "&gt;")
    escaped2 = escaped.gsub("/", "&#47;") # for Slim w/ Rails > 3.0 (??)

    expect(clean_whitespace(presenter.erb_escaping)).to eq(escaped + unescaped)
    expect(clean_whitespace(presenter.haml_escaping)).to eq(escaped + unescaped)

    expect([escaped + unescaped, escaped2 + unescaped]).to include(
      clean_whitespace(presenter.slim_escaping)
    )
  end

  it "sees updates after the file is reloaded" do
    expect(presenter.simple_template.strip).to eq("Here's some math: 4")

    allow_any_instance_of(Keynote::Inline::Cache)
      .to receive(:read_template).and_return("HELLO")

    expect(presenter.simple_template.strip).to eq("Here's some math: 4")

    allow(File).to receive(:mtime).with(
      Object.const_source_location(:InlineUserPresenter).first
    ).and_return(Time.now + 1)

    expect(presenter.simple_template).to eq("HELLO")
  end
end
