# frozen_string_literal: true

describe Keynote::Railtie do
  let(:controller) { HelloController.new }
  let(:context) { controller.view_context }

  it "makes the present and k methods available to controllers" do
    expect(controller).to respond_to(:present)
    expect(controller).to respond_to(:k)
  end

  it "makes the present and k methods available to views" do
    expect(context).to respond_to(:present)
    expect(context).to respond_to(:k)
  end

  it "passes present call from controller to Keynote.present" do
    context = double
    allow(controller).to receive(:view_context).and_return(context)

    expect(Keynote).to receive(:present).with(context, :dallas, :leeloo, :multipass)

    controller.present(:dallas, :leeloo, :multipass)
  end

  it "passes present call from view to Keynote.present" do
    expect(Keynote).to receive(:present).with(context, :dallas, :leeloo, :multipass)

    context.present(:dallas, :leeloo, :multipass)
  end
end
