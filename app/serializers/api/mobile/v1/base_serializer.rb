# frozen_string_literal: true

# Base class for the mobile API serializers.
#
# Intentionally a plain Ruby class (no ActiveModelSerializers): each
# subclass takes a single model instance plus optional keyword options
# and exposes `#as_json` returning a Hash with the exact response shape
# the mobile app expects.
#
# Subclasses should implement `#as_json` directly. Use `.collection`
# to map an enumerable of records into an array of serialized hashes
# using the same serializer.
class Api::Mobile::V1::BaseSerializer
  def initialize(object, **options)
    @object = object
    @options = options
  end

  def self.collection(records, **options)
    Array(records).map { |record| new(record, **options).as_json }
  end

  def as_json(*)
    raise NotImplementedError, "#{self.class} must implement #as_json"
  end

  private

  attr_reader :object, :options
end
