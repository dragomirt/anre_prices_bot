# This file is autogenerated. Do not edit it by hand. Regenerate it with:
#   srb rbi gems

# typed: strict
#
# If you would like to make changes to this file, great! Please create the gem's shim here:
#
#   https://github.com/sorbet/sorbet-typed/new/master?filename=lib/axiom-types/all/axiom-types.rbi
#
# axiom-types-0.1.1

module Axiom
end
module Axiom::Types
  def self.finalize; end
  def self.infer(object); end
end
module Axiom::Types::Options
  def accept_options(*new_options); end
  def accepted_options; end
  def assert_method_available(name); end
  def define_option_method(name); end
  def inherited(descendant); end
  def options; end
  def setup_option(new_option); end
end
class Axiom::Types::Options::ReservedMethodError < ArgumentError
end
class Axiom::Types::Infinity
  def <=>(other); end
  def coerce(other); end
  def inverse; end
  def self.allocate; end
  def self.inverse(*args); end
  def self.new(*arg0, **); end
  def self.number(*args); end
  def succ; end
  extend Axiom::Types::Options
  extend Singleton::SingletonClassMethods
  include Comparable
end
class Axiom::Types::NegativeInfinity < Axiom::Types::Infinity
  def <=>(_other); end
end
module Axiom::Types::ValueComparable
  def finalize; end
  def range; end
  def self.extended(descendant); end
  def use_value_within_range; end
end
module Axiom::Types::LengthComparable
  def finalize; end
  def range; end
  def self.extended(descendant); end
  def use_length_within_range; end
end
module Axiom::Types::Encodable
  def ascii_compatible?; end
  def finalize; end
  def self.extended(descendant); end
  def use_ascii_compatible_encoding; end
  def use_encoding; end
end
class Axiom::Types::Type
  def self.add_constraint(constraint); end
  def self.anonymous?; end
  def self.base; end
  def self.base?; end
  def self.constraint(constraint = nil, &block); end
  def self.finalize; end
  def self.include?(object); end
  def self.includes(*members); end
  def self.infer(object); end
  def self.new(*args, &block); end
  extend Axiom::Types::Options
end
class Axiom::Types::Object < Axiom::Types::Type
  def self.coercion_method(*args); end
  def self.finalize; end
  def self.infer(object); end
  def self.infer_from_primitive_class(object); end
  def self.inherits_from_primitive; end
  def self.inspect; end
  def self.match_primitive?(object); end
  def self.primitive(*args); end
end
class Axiom::Types::Collection < Axiom::Types::Object
  def self.base?; end
  def self.finalize; end
  def self.infer(object); end
  def self.infer_from(member_type); end
  def self.infer_from_primitive_instance(object); end
  def self.match_primitive?(*arg0); end
  def self.matches_member_type; end
  def self.member_type(*args); end
  def self.new_from(member_type); end
end
class Axiom::Types::Numeric < Axiom::Types::Object
  def self.maximum(*args); end
  def self.minimum(*args); end
  extend Axiom::Types::ValueComparable
end
class Axiom::Types::Array < Axiom::Types::Collection
  def self.base?; end
end
class Axiom::Types::Boolean < Axiom::Types::Object
  def self.infer_from_primitive_class(object); end
end
class Axiom::Types::Class < Axiom::Types::Object
end
class Axiom::Types::Date < Axiom::Types::Object
  def self.maximum(*args); end
  def self.minimum(*args); end
  extend Axiom::Types::ValueComparable
end
class Axiom::Types::DateTime < Axiom::Types::Object
  def self.maximum(*args); end
  def self.minimum(*args); end
  extend Axiom::Types::ValueComparable
end
class Axiom::Types::Decimal < Axiom::Types::Numeric
end
class Axiom::Types::Float < Axiom::Types::Numeric
end
class Axiom::Types::Hash < Axiom::Types::Object
  def self.base?; end
  def self.finalize; end
  def self.infer(object); end
  def self.infer_from(key_type, value_type); end
  def self.infer_from_primitive_instance(object); end
  def self.key_type(*args); end
  def self.match_primitive?(*arg0); end
  def self.matches_key_and_value_types; end
  def self.new_from(key_type, value_type); end
  def self.value_type(*args); end
end
class Axiom::Types::Integer < Axiom::Types::Numeric
end
class Axiom::Types::Set < Axiom::Types::Collection
  def self.base?; end
end
class Axiom::Types::String < Axiom::Types::Object
  def self.encoding(*args); end
  def self.maximum_length(*args); end
  def self.minimum_length(*args); end
  extend Axiom::Types::LengthComparable
end
class Axiom::Types::Symbol < Axiom::Types::Object
  def self.encoding(*args); end
  def self.maximum_length(*args); end
  def self.minimum_length(*args); end
  extend Axiom::Types::LengthComparable
end
class Axiom::Types::Time < Axiom::Types::Object
  def self.maximum(*args); end
  def self.minimum(*args); end
  extend Axiom::Types::ValueComparable
end
