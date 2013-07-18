require "spec_helper"

describe RailsSettings do
  before(:all) do
    @str = "Foo bar"
    @tm = Time.now
    @items = [1,3,5,'as']
    @hash = { :name => @str, :items => @items }
    @merged_hash = { :name => @str, :items => @items, :id => 32 }
    @bar = "Bar foo"
    @user = User.create(:login => 'test', :password => 'foobar')
  end

  describe "Implementation" do
    context 'settings life cycle' do
      it "can not save setting without namespace" do
        ->{Setting[:foo]}.should raise_error Setting::NamespaceNotProvided
      end

      it "can work with String value" do
        Setting[:en => :foo] = @str
        Setting.foo(:en).should == @str
      end

      it "can work with Array value" do
        Setting[:en => :items] = @items
        Setting.items(:en).should == @items
        Setting.items(:en).class.should == @items.class
      end

      it "can work with DateTime value" do
        Setting[:be => :created_on] = @tm
        Setting.created_on(:be).should == @tm
      end

      it "can work with Hash value" do
        Setting[:en => :hashes] = @hash
        Setting.hashes(:en).should == @hash
        Setting.hashes(:en).class.should == @hash.class
      end

      it "can work with Merge to merge a Hash" do
        Setting.merge!(:en, :hashes, :id => 32)
        Setting.hashes(:en).should == @merged_hash
      end

      it "can read old data" do
        Setting.foo(:en).should == @str
        Setting.items(:en).should == @items
        Setting.created_on(:be).should == @tm
        Setting.hashes(:en).should == @merged_hash
      end

      it "can list all entries by Setting.all" do
        Setting.all.count.should == 4
        Setting.all(:be).count.should == 1
      end

      it "can destroy a value" do
        Setting.destroy(:en, :foo)
        Setting.foo(:en).should == nil
        Setting.all.count.should == 3
      end
    end

    context 'working with default values' do
      it "sets default value | takes it if no value exists for the namespace" do
        Setting.defaults[:bar] = @bar
        Setting.bar(:en).should == @bar
      end

      it "sets default value | throws an error if no namespace provided" do
        Setting.defaults[:bar] = @bar
        ->{Setting.bar}.should raise_error Setting::NamespaceNotProvided
      end

      it "sets default | takes specialised value for the namespace" do
        Setting.defaults[:bar] = @bar
        Setting[:en => :bar] = @str
        Setting.bar(:en).should == @str
        Setting.bar(:be).should == @bar
      end

      it "can use default value, when the setting it cached with nil value" do
        Setting.has_cached_nil_key(:en)
        Setting.defaults[:has_cached_nil_key] = "123"
        Setting.has_cached_nil_key(:en).should == "123"
      end

      it "#save_default" do
        Setting.test_save_default_key(:en)
        Setting.save_default(:en, :test_save_default_key, "321")
        Setting.where(:var => "test_save_default_key", :namespace => "en").count.should == 1
        Setting.test_save_default_key(:en).should == "321"
        Setting.save_default(:en, :test_save_default_key, "3211")
        Setting.test_save_default_key(:en).should == "321"
      end
    end
  end

  describe "Implementation by embeds a Model" do
    it "can set values" do
      @user.settings[:en => :level] = 30
      @user.settings[:en => :locked] = true
      @user.settings[:en => :last_logined_at] = @tm
    end

    it "can read values" do
      @user.settings.level(:en).should == 30
      @user.settings.locked(:en).should == true
      @user.settings.last_logined_at(:en).should == @tm
    end
  end
end
