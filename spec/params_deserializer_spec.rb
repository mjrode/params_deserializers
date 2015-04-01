require_relative '../lib/params_deserializer'

describe ParamsDeserializer do
  describe 'basic' do

    subject do
      Class.new(ParamsDeserializer) do
        attributes :id, :name
      end
    end

    let(:params) do
      { id: 5, name: 'foo' }
    end

    it 'copies an old param to a new param' do
      instance = subject.new(params)
      new_params = instance.deserialize
      expect(new_params[:id]).to eql(params[:id])
      expect(new_params[:name]).to eql(params[:name])
    end
  end

  describe 'pseudo-params' do
    subject do
      Class.new(ParamsDeserializer) do
        attributes :id, :name
        def name; 'foo'; end
      end
    end

    let(:params) do
      { id: 5 }
    end

    it 'allows deserialization of a param that does not exist' do
      instance = subject.new(params)
      new_params = instance.deserialize
      expect(new_params[:id]).to eql(params[:id])
      expect(new_params[:name]).to eql('foo')
    end
  end

  describe 'overrides' do
    subject do
      Class.new(ParamsDeserializer) do
        attributes :foo
        def foo; 'bar'; end
      end
    end

    it 'allows method access for params?' do
      instance = subject.new({foo: 'baz'})
      new_params = instance.deserialize

      expect(new_params[:foo]).to eql('bar')
    end
  end

  describe 'has_many' do
    context 'with overrides' do
      subject do
        Class.new(ParamsDeserializer) do
          has_many :foos, to: :foos_attributes
        end
      end

      it 'puts the new key in to new_params' do
        instance = subject.new(foos: [{bar: 1}])
        new_params = instance.deserialize

        expect(new_params[:foos_attributes]).to eql([{ bar: 1 }])
      end
    end

    context 'without overrides' do
      subject do
        Class.new(ParamsDeserializer) do
          has_many :foos
        end
      end

      it 'defaults to the key provided' do
        instance = subject.new(foos: [{bar: 1}])
        new_params = instance.deserialize

        expect(new_params[:foos]).to eql([{ bar: 1 }])
      end
    end

    context 'with a sub-deserializer' do
      subject do
        foo_deserializer = Class.new(ParamsDeserializer) do
          attributes :baz
        end

        Class.new(ParamsDeserializer) do
          has_many :foos, deserializer: foo_deserializer
        end
      end

      it 'uses a provided sub-deserializer for each item in a has_many relationship' do
        instance = subject.new(foos: [{ bar: 1, baz: 2},
                                      { bar: 3, baz: 4 }])
        new_params = instance.deserialize

        expect(new_params[:foos]).to eql([{ baz: 2 }, { baz: 4 }])
      end
    end
  end
end
