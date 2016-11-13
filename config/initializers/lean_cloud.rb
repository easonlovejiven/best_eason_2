LeanCloud.configure do
  YAML.load_file(Rails.root.join('config', 'lean_cloud.yml'))[Rails.env].to_a.each do |k, v|
    config.send("#{k}=", v)
  end
end