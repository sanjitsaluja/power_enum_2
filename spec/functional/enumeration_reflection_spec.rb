require 'spec_helper'

describe PowerEnum::Reflection::EnumerationReflection do
  it 'should add reflection via reassigning reflections hash' do
    Booking.reflections.object_id.should_not == Adapter.reflections.object_id
  end

  context 'Booking should have a reflection for each enumerated attribute' do

    [:state, :status].each do |enum_attr|
      it "should have a reflection for #{enum_attr}" do
        reflection = Booking.reflections[enum_attr.to_s]
        expect(Booking.reflect_on_enumerated(enum_attr)).to eq reflection

        reflection.should_not be_nil
        reflection.chain.should =~ [reflection]
        reflection.check_validity!
        reflection.source_reflection.should be_nil
        reflection.conditions.should == [[]]
        reflection.type.should be_nil
        reflection.source_macro.should == :belongs_to
        reflection.belongs_to?.should eq(true)
        reflection.name.to_sym.should == enum_attr
        reflection.active_record.should == Booking
        reflection.should respond_to(:counter_cache_column)
        reflection.macro.should == :has_enumerated
        reflection.should be_kind_of(PowerEnum::Reflection::EnumerationReflection)
      end
    end

    it 'should be able to reflect on all enumerated' do
      expect(Booking.respond_to?(:reflect_on_all_enumerated)).to eq(true)
      expect(Booking.reflect_on_all_enumerated.map(&:name).to_set).to eq( [:state, :status].to_set )
    end

    it 'should include enumerations as associations' do
      Booking.reflect_on_all_associations.map(&:name).to_set.should == [:state, :status].to_set
    end

    it 'should have reflection on has_enumerated association' do
      expect(Booking.reflect_on_enumerated(:state)).to_not be_nil
      expect(Booking.reflect_on_enumerated('status')).to_not be_nil
    end

    it 'should have reflection on association' do
      expect(Booking.reflect_on_association(:state)).to_not be_nil
      expect(Booking.reflect_on_association('status')).to_not be_nil
    end

    it 'should have reflection properly built' do
      reflection = Booking.reflect_on_enumerated(:status)
      expect(reflection.klass).to eq BookingStatus
      expect(reflection.options[:foreign_key]).to eq :status_id
      expect(reflection.options[:on_lookup_failure]).to eq :not_found_status_handler
      expect(reflection.association_class).to eq(::ActiveRecord::Associations::HasOneAssociation)
    end

    it 'should have the correct table name' do
      Booking.reflections['state'].table_name.should == 'states'
      Booking.reflections['status'].table_name.should == 'booking_statuses'
    end
  end

  context 'joins' do
    before :each do
      [:confirmed, :received, :rejected].map{|status|
        booking = Booking.create(:status => status)
        booking
      }
    end

    after :each do
      Booking.destroy_all
    end

    it 'should build a valid join' do
      bookings = Booking.joins(:status)
      bookings.size.should == 3
    end

    it 'should allow conditions on joined tables' do
      bookings = Booking.joins(:status).where(:booking_statuses => {:name => :confirmed})
      bookings.size.should == 1
      bookings.first.status.should == BookingStatus[:confirmed]
    end
  end
end
