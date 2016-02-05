Product.find_each{|product| product.send(:save_to_fts) }
UserProduct.find_each{|up| up.send(:save_to_fts) }
