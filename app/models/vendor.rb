class Vendor
  include Mongoid::Document
  include Mongoid::Slug
  field :company, type: String
  field :category, type: String

  slug :company

  has_one :address
  embeds_many :contact_persons 
  
  accepts_nested_attributes_for :contact_persons, :address
  validates :company, :category, presence: true

  def self.process_vendors_csv_file(row)
    vendor = Vendor.where(company: row[2], category: row[3]).first
    unless vendor.nil?
      check_contact_and_update(vendor, row)
    else
      vendor = Vendor.new(company: row[2], category: row[3])
      vendor.contact_persons.build(name: row[1], role: row[4], phone_no: row[5], email: row[6]) 
    end
    vendor.save
  end

  def self.check_contact_and_update(vendor, row)
    contact = get_contact(vendor, row) if record_exists(vendor, row)
    update_contact_person(contact || nil, vendor, row) 
  end

  def self.record_exists(vendor, row)
    return vendor.contact_persons.any_of({name: row[1], role: row[4]}, {phone_no: row[5]}).present?
  end

  def self.get_contact(vendor, row)
    return vendor.contact_persons.any_of({name: row[1], role: row[4]}, {phone_no: row[5]}).first
  end

  def self.update_contact_person(contact, vendor, row)
    unless contact
      vendor.contact_persons.build(name: row[1], role: row[4], phone_no: row[5], email: row[6]) 
    else
      contact_person = vendor.contact_persons.find(contact.id)
      contact_person.update_attributes(name: row[1], role: row[4], phone_no: row[5], email: row[6])
    end
  end
end
