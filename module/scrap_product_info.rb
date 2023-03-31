# Собираем инфу товара
module ScrapProductInfo
  def self.scrap_product_info(product_setting, driver)
    product_info = {}

    begin
      # собираем название
      if !product_setting[:name].empty? || driver.find_elements(:css, product_setting[:name]).size() > 0
        name = driver.find_element(:css, product_setting[:name].to_s).text
        product_info['Название товара или услуги'] = name
        puts("Собираем информацию товара.Текущий - #{name}")
      else
        product_info['Название товара или услуги'] = ''
      end
      # собираем цену
      if !product_setting[:price].empty? && driver.find_elements(:css, product_setting[:price]).size() > 0
        price = driver.find_element(:css, product_setting[:price]).text.gsub(/[^\d,\.]/, '')
        product_info['Цена продажи'] = price
      else
        product_info['Цена продажи'] = ''
      end
      # собираем артикул
      if !product_setting[:sku].empty? && driver.find_elements(:css, product_setting[:sku]).size() > 0
        sku = driver.find_element(:css, product_setting[:sku]).text

        product_info['Артикул'] = sku
      end
      # собираем старый урл
      old_url = driver.current_url
      product_info['old_url'] = old_url
      # собираем категорию
      unless product_setting[:product_directory].empty? && !driver.find_elements(:css, product_setting[:product_directory]).size() > 0
        product_directory = driver.find_element(:css, product_setting[:product_directory]).text.sub(name, '')
        product_info['Размещение на сайте'] = product_directory
      end
      # собираем краткое описание
      unless product_setting[:short_description].empty? || !driver.find_elements(:css, product_setting[:short_description]).size() > 0
        short_description = driver.find_element(:css, product_setting[:short_description]).attribute('innerHTML')
        product_info['Краткое описание'] = short_description
      end
      # собираем описание
      unless product_setting[:description].empty? && !driver.find_elements(:css, product_setting[:description]).size() > 0
        description = driver.find_element(:css, product_setting[:description]).attribute('innerHTML')
        product_info['Полное описание'] = description
      end
      # собираем параметры.
      unless product_setting[:properties_block].empty? && !driver.find_elements(:css, product_setting[:properties_block]).size() > 0
        properties_block = driver.find_element(:css, product_setting[:properties_block])
        # Так как параметры скрыты при загрузке страницы, делаем их видимыми
        driver.execute_script('arguments[0].style.display = "block"', properties_block)
        unless product_setting[:property].empty? && !driver.find_elements(:css, product_setting[:property]).size() > 0
          properties = properties_block.find_elements(:css, product_setting[:property])

          properties.each do |prop|
            prop_title = prop.find_element(:css, product_setting[:prop_title]).text
            prop_value = prop.find_element(:css, product_setting[:prop_value]).text

            product_info["Параметр: #{prop_title}"] = prop_value
          end
        end
      end
      #  Собираем изображения
      if driver.find_elements(:css, product_setting[:images]).size() > 0
        all_images = []
        image = driver.find_elements(:css, product_setting[:images])
        image.each { |link| all_images << link.attribute('href') }
        product_info['Изображения'] = all_images.join(', ')
      end

      product_info

    # Todo добавить нормальную обработку ошибок
    rescue Selenium::WebDriver::Error::NoSuchElementError
      puts 'error'
      product_info
    end
  end
end
