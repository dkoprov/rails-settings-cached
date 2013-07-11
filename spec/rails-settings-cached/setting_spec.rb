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
    it "can not save setting without namespace" do
      ->{Setting[:foo]}.should raise_error(Settings::NamespaceNotProvided)
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

    it "can work with namespace key" do
      Setting['en' => 'config.color'] = :red
      Setting['en' => 'config.limit'] = 100
    end

    it "can read last give namespace key's value" do
      Setting['en' => 'config.color'].should == :red
      Setting['en' => 'config.limit'].should == 100
    end

    it "can work with Merge to merge a Hash" do
      Setting.merge!(:hashes, :id => 32)
      Setting.hashes.should == @merged_hash
    end

    it "can read old data" do
      Setting.foo(:en).should == @str
      Setting.items(:en).should == @items
      Setting.created_on(:be).should == @tm
      Setting.hashes(:en).should == @merged_hash
    end

    it "can list all entries by Setting.all" do
      Setting.all.count.should == 6
      Setting.all(:be).count.should == 1
    end

    it "can destroy a value" do
      Setting.destroy(:foo, :en)
      Setting.foo(:en).should == nil
      Setting.all.count.should == 5
    end

    it "can work with default value" do
      Setting.defaults[:bar] = @bar
      Setting.bar.should == @bar
    end

    it "can use default value, when the setting it cached with nil value" do
      Setting.has_cached_nil_key
      Setting.defaults[:has_cached_nil_key] = "123"
      Setting.has_cached_nil_key.should == "123"
    end

    it "#save_default" do
      Setting.test_save_default_key
      Setting.save_default(:test_save_default_key, "321")
      Setting.where(:var => "test_save_default_key").count.should == 1
      Setting.test_save_default_key.should == "321"
      Setting.save_default(:test_save_default_key, "3211")
      Setting.test_save_default_key.should == "321"
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
