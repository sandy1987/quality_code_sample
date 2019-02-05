class Hash
  def symbolize
    self.each_with_object({}) do |(key, val), res|
      nkey = key.is_a?(String) ? key.to_sym : key
      nval = case val
             when Hash, Array then val.symbolize
             when String      then val
             else val
             end
      res[nkey] = nval
    end
  end
end