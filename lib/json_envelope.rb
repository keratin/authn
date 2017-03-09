module JSONEnvelope
  def self.result(data = {})
    {
      'result' => data
    }
  end

  def self.errors(errors)
    {
      'errors' => errors.map do |a, m|
        {'field' => a, 'message' => m}
      end
    }
  end
end
