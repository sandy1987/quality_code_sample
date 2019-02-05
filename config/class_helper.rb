#encoding: utf-8
class Array
  # convert to arg list - similar to flatten, but only if 1st arg is an array
  def to_sargs
    size == 1 && (a = at(0)).is_a?(Array) ? a : self
  end

   # symbolize all string hash keys
  def symbolize(recurse = true)
    self.map { |e| recurse && (e.is_a?(Array) || e.is_a?(Hash)) ? e.symbolize : e }
  end

  def symbolize!(recurse = true)
    self.map! { |e| recurse && (e.is_a?(Array) || e.is_a?(Hash)) ? e.symbolize! : e }
  end

end

class Hash

  def delete_keys(*keys)
    keys.a_to_sargs.inject({}) { |h, k| h[k] = delete(k) if has_key?(k); h }
  end

  # Remove the key that has value 'empty' or nil (not false).
  # Note: It works only for one dimensional hash and dont trim leading/trailing spaces
  def except_empty
    self.reject{|k, v| v.to_s.empty?}
  end

  def except_empty!
    self.delete_if{|k, v| v.to_s.empty?}
  end

  def except_empty_with_trim
    self.except_empty.inject({}) {|r, (k,v)| r.merge(k => v.is_a?(String)? v.strip : v)}
  end

  def except_empty_with_trim!
    self.except_empty!.inject({}) {|r, (k,v)| r.merge(k => v.is_a?(String)? v.strip : v)}
  end

  # includes keys
  def includes?(*keys)
    keys.to_sargs.all? {|k| key?(k) }
  end

  # includes keys w/o empty strings
  def includes!(*keys)
    keys.to_sargs.all? {|k| v = self[k]; !v.nil? && !(v.is_a?(String) && v.empty?) }
  end

  # return only those keys listed
  def only(*keys)
    keys = keys.to_sargs
    self.select { |k| keys.include?(k) } || self
  end

  def only!(*keys)
    keys = keys.to_sargs
    self.keep_if { |k| keys.include?(k) }
  end

  # fetch param if not nil or empty string
  def param(k)
    v = self[k.to_sym] || self[k.to_s]
    v && !(v.is_a?(String) && v.empty?) ? v : nil
  end

  def strip_val
    self.inject({}) {|r, (k, v)| r.merge(k => v.is_a?(String) ? v.strip : v)}
  end

  def symbolize(recurse = true)
    self.inject({}) do |h, (k, v)|
      h[k.to_sym] = recurse && (v.is_a?(Array) || v.is_a?(Hash)) ? v.symbolize : v
      h
    end
  end

  def symbolize!(recurse = true)
    keys.each do |k|
      if k.is_a?(String)
        store(k.to_sym, v = delete(k))
      else
        v = self[k]
      end
      v.symbolize! if recurse && (v.is_a?(Array) || v.is_a?(Hash))
    end
    self
  end

  # return all keys except those listed
  def without(*keys)
    keys = keys.to_sargs
    self.reject { |k| keys.include?(k) } || self
  end

  def without!(*keys)
    keys = keys.to_sargs
    self.delete_if { |k| keys.include?(k) }
  end

end

class NilClass
  def empty?
    true
  end
  
  # Due to this getting confirmation/reset token invalid error
  # def strip
  #   ""
  # end

  def strip!
    ""
  end

  def to_i
    0
  end

  def to_sym
    self
  end

  def first
    nil
  end

end

class String

  # Only capitalize first letter of a string
  def capitalize_first
    self.sub(/\S/, &:upcase)
  end

  # check if a string is numeric "12" is numeric while "aa" is not
  # Ref. http://mentalized.net/journal/2011/04/14/ruby_how_to_check_if_a_string_is_numeric/
  def numeric?
    Integer(self) != nil rescue false
  end

  def to_bool
    return true if ['t', 'true', '1', 'yes'].include?(self)
    return false if ['f', 'false', '0', 'no'].include?(self)
    raise ArgumentError, :not_a_boolean_value_t_f_1_0_yes_no
  end

  def dimension
    # remove paperclip geometry
    self.gsub!('#', '')
    # Assuming string is in "WxH" format
    s = self.split('x')
    { w: s[0].to_i, h: s[1].to_i }
  end

end
