# frozen_string_literal: true

describe Keynote do
  let(:view) { Object.new }

  describe ".present" do
    let(:model) { Normal.new }

    it "finds and instantiates implicitly" do
      p = Keynote.present(view, model)

      expect(p).not_to be_nil
      expect(p).to be_a(NormalPresenter)

      expect(p.view).to eq(view)
      expect(p.model).to eq(model)
    end

    it "finds and instantiates explicitly" do
      p = Keynote.present(view, :normal, "hello")

      expect(p).not_to be_nil
      expect(p).to be_a(NormalPresenter)

      expect(p.view).to eq(view)
      expect(p.model).to eq("hello")
    end

    it "takes a block and passes the presenter into it" do
      m = double
      expect(m).to receive(:block_yielded)

      Keynote.present(view, :normal, "hello") do |p|
        m.block_yielded

        expect(p).not_to be_nil
        expect(p).to be_a(NormalPresenter)

        expect(p.view).to eq(view)
        expect(p.model).to eq("hello")
      end
    end

    it "integrates with Rumble" do
      p = Keynote.present(view, model)
      rx = /<div>&lt;script&gt;alert\(/

      expect(p.some_bad_html.scan(rx).count).to eq(3)
    end

    context "with a nested presenter" do
      let(:model) { Foo::Bar.new }

      it "finds and instantiates implicitly" do
        p = Keynote.present(view, model)

        expect(p).not_to be_nil
        expect(p).to be_a(Foo::BarPresenter)

        expect(p.view).to eq(view)
        expect(p.model).to eq(model)
      end

      it "finds and instantiates explicitly" do
        p = Keynote.present(view, "foo/bar", "hello")

        expect(p).not_to be_nil
        expect(p).to be_a(Foo::BarPresenter)

        expect(p.view).to eq(view)
        expect(p.model).to eq("hello")
      end
    end

    context "caching" do
      describe "when there is a view context" do
        let(:view_2) { Object.new }

        it "caches based on the models" do
          model_1 = Normal.new
          model_2 = Normal.new

          presented_1 = Keynote.present(view, model_1)
          presented_2 = Keynote.present(view, model_1)

          expect(presented_1).to equal(presented_2)

          presented_3 = Keynote.present(view, :combined, model_1, model_2)
          presented_4 = Keynote.present(view, :combined, model_1, model_2)
          presented_5 = Keynote.present(view, :combined, model_2, model_1)

          expect(presented_3).not_to equal(presented_1)
          expect(presented_3).to equal(presented_4)
          expect(presented_3).not_to equal(presented_5)
        end

        it "caches even if there are no models" do
          presenter_1 = Keynote.present(view, :empty)
          presenter_2 = Keynote.present(view, :empty)

          expect(presenter_1).to equal(presenter_2)
        end

        it "is scoped to the specific view context" do
          model = Normal.new

          presenter_1 = Keynote.present(view, model)
          expect(presenter_1.view).to eq(view)

          presenter_2 = Keynote.present(view_2, model)
          expect(presenter_2).not_to equal(presenter_1)
          expect(presenter_2.view).to eq(view_2)
        end
      end

      describe "when there's no view context" do
        it "does not cache" do
          model = Normal.new

          presented_1 = Keynote.present(nil, model)
          presented_2 = Keynote.present(nil, model)

          expect(presented_1).not_to equal(presented_2)
        end
      end
    end
  end
end
