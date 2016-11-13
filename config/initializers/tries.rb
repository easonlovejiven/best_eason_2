class Object
  def tries(*args)
    record = self
    args.each{ |a| record = record.try(a) }
    record
  end
end