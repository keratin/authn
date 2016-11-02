module JSONEnvelope
  def self.result(data)
    {
      'result' => data
    }
  end

  def self.errors(errors)
    {
      'errors' => errors.map{|a, m|
        {'field' => a, 'message' => m}
      }
    }
  end
end
