class Hermes::NullInstrumenter
  def self.instrument(name, payload = {})
    yield
  end
end
