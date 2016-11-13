desc "导入数据库数据到es"
task search: :environment do
  Core::User.reindex
  Shop::Task.reindex
  Shop::Product.reindex
end
