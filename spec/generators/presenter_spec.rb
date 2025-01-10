# frozen_string_literal: true

require "ammeter/init"
require_relative "../../lib/generators/presenter_generator"

RSpec.describe Rails::Generators::PresenterGenerator do
  destination File.expand_path("../../tmp", __FILE__)

  before { prepare_destination }
  after { FileUtils.rm_rf(destination_root) }

  let(:generators_config) { double }

  before { allow(Rails.application.config).to receive(:generators).and_return(generators_config) }

  it "generates a presenter and RSpec file" do
    allow(generators_config).to receive(:rails).and_return({test_framework: :rspec})

    run_generator ["post"]
    expect(file("app/presenters/post_presenter.rb")).to contain(/class PostPresenter < Keynote::Presenter/)
    expect(file("spec/presenters/post_presenter_spec.rb")).to contain(/describe PostPresenter do/)
  end

  it "generates a presenter and MiniTest::Rails spec file" do
    allow(generators_config).to receive(:rails).and_return({test_framework: :mini_test})
    allow(generators_config).to receive(:mini_test).and_return({spec: true})

    run_generator ["post"]
    expect(file("app/presenters/post_presenter.rb")).to contain(/class PostPresenter < Keynote::Presenter/)
    expect(file("test/presenters/post_presenter_test.rb")).to contain(/describe PostPresenter do/)
  end

  it "generates a presenter and MiniTest::Rails unit file" do
    allow(generators_config).to receive(:rails).and_return({test_framework: :mini_test})
    allow(generators_config).to receive(:mini_test).and_return({spec: false})

    run_generator ["post"]
    expect(file("app/presenters/post_presenter.rb")).to contain(/class PostPresenter < Keynote::Presenter/)
    expect(file("test/presenters/post_presenter_test.rb")).to contain(/class PostPresenterTest < Keynote::TestCase/)
  end
end
