# frozen_string_literal: true

describe Keynote::Presenter do
  before do
    stub_const("TestPresenter", Class.new(Keynote::Presenter))
  end

  let(:presenter_class) { TestPresenter }

  describe "delegation" do
    let(:klass) do
      Class.new(presenter_class) do
        presents :grizzly, :bear
        delegate :adams, to: :grizzly
        delegate :man, to: :grizzly, prefix: true
      end
    end

    it "uses ActiveSupport Module#delegate method" do
      mock = double
      expect(mock).to receive(:adams)
      expect(mock).to receive(:man)

      klass.new(nil, mock, nil).tap do |p|
        p.adams
        p.grizzly_man
      end
    end
  end

  describe ".presents" do
    it "takes just the view context by default" do
      klass = Class.new(presenter_class)

      expect(klass.new(1).instance_variable_get(:@view)).to eq(1)
    end

    describe "with two parameters" do
      let(:klass) do
        Class.new(presenter_class) do
          presents :grizzly, :bear
        end
      end

      it "lets you specify other objects to take" do
        presenter = klass.new(1, 2, 3)
        expect(presenter.instance_variable_get(:@view)).to eq(1)
        expect(presenter.instance_variable_get(:@grizzly)).to eq(2)
        expect(presenter.instance_variable_get(:@bear)).to eq(3)
      end

      it "is not callable with the wrong arity" do
        expect { klass.new(1, 2) }.to raise_error(ArgumentError)
      end

      it "generates readers for the objects" do
        p = klass.new(1, 2, 3)
        expect(p.view).to eq(1)
        expect(p.grizzly).to eq(2)
        expect(p.bear).to eq(3)
      end
    end
  end

  describe ".use_html5_tags" do
    let(:klass) do
      Class.new(presenter_class) do
        def generate_h3(content)
          build_html { h3 content }
        end

        def generate_small(content)
          build_html { small content }
        end
      end
    end

    it "adds Rumble tags like `small` while preserving existing tags" do
      presenter = klass.new(nil)

      expect(presenter.generate_h3("hi")).to eq("<h3>hi</h3>")
      expect { presenter.generate_small("uh-oh") }.to raise_error(NoMethodError)

      klass.use_html_5_tags

      expect(presenter.generate_h3("hi")).to eq("<h3>hi</h3>")
      expect(presenter.generate_small("hi")).to eq("<small>hi</small>")
    end
  end

  describe ".object_names" do
    it "doesn't leak between classes" do
      c1 = Class.new(Keynote::Presenter)
      c2 = Class.new(Keynote::Presenter)

      c1.object_names << :foo
      expect(c1.object_names).to eq([:foo])
      expect(c2.object_names).to eq([])
    end

    it "matches the list of presented objects" do
      c = Class.new(Keynote::Presenter)
      expect(c.object_names).to eq([])
      c.presents :biff, :bam, :pow
      expect(c.object_names).to eq([:biff, :bam, :pow])
    end
  end

  describe "#present" do
    it "passes its view context through to the new presenter" do
      mock = double
      expect(mock).to receive(:pizza)

      p1 = presenter_class.new(mock)
      p2 = p1.present(:test)

      expect(p1).not_to eq(p2)
      p2.pizza
    end
  end

  describe "#inspect" do
    it "includes the class name" do
      expect(CombinedPresenter.new(:view, :a, :b).inspect)
        .to match(/^#<CombinedPresenter /)
    end

    it "shows .inspect output for each presented object" do
      c1 = Class.new(Object) {
        def inspect
          "c1"
        end
      }
      c2 = Class.new(Object) {
        def inspect
          "c2"
        end
      }
      p = CombinedPresenter.new(:view, c1.new, c2.new)

      expect(p.inspect).to eq("#<CombinedPresenter model_1: c1, model_2: c2>")
    end

    it "leaves no extra padding for zero-arg presenters" do
      expect(EmptyPresenter.new(:view).inspect).to eq("#<EmptyPresenter>")
    end
  end

  describe "#method_missing" do
    it "passes unknown method calls through to the view" do
      mock = double
      expect(mock).to receive(:talking).with(:heads)

      object = Class.new do
        define_method(:talking) do |arg|
          mock.talking(arg)
        end
        private :talking
      end.new

      presenter_class.new(object).talking(:heads)
    end

    it "responds to methods of the view" do
      object = Class.new do
        define_method(:talking) do |arg|
        end
        private :talking
      end.new

      expect(presenter_class.new(object).respond_to?(:talking)).to be true
    end

    it "raises unknown methods at the presenter, not the view" do
      err = nil

      begin
        Keynote::Presenter.new(Object.new).talking(:heads)
      rescue NoMethodError => e
        err = e
      end

      expect(err).not_to be_nil
      expect(err.message).to match(/Keynote::Presenter/)
    end
  end
end
