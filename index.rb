require 'csv'
require 'selenium-webdriver'
require './module/connection'
require './module/scrap_product_info'
require './module/pagination'

# собираем продукты
class CollectProducts
  # подключаем модули
  include Connection
  include ScrapProductInfo
  include Pagination

  def initialize
    @main_page = 'https://tdelics.ru/collection/all'
    @first_page = ['https://tdelics.ru/collection/all']
    @scraping_pages = ['https://tdelics.ru/collection/all']
    @pagination_css = '.pagination-items .pagination-link'
    @product_css = 'li.product'
    @product_link_css = '.product a'
    @all_products = []
    @products_urls = []
    @driver = Connection.set_driver

    @product_setting = {
      name: '.product__title.heading',
      price: '.product__price-cur',
      sku: '.sku-value',
      product_directory: '.breadcrumb-wrapper .breadcrumb',
      short_description: '',
      description: '.product-description',
      properties_block: '#tab-characteristics',
      property: '.property',
      prop_title: '.property__name',
      prop_value: '.property__content',
      images: '.js-product-all-images .product__slide-main a'
    }
  end

  def init
    # Есть два варианта - когда все товары долступны на одной странице с паг-ей и когда товары в категориях. Для каждой свой алгоритм.
    # В файле pagination нужно задать селект пагинации страниц в gsub
    
    # 1)Первый вариант

    # собираем страницы
    #page(@scraping_pages[0])
    #Pagination.pagination_pages(@scraping_pages, @pagination_css, @driver)

    # собираем линки товаров
    #@scraping_pages.each do |item|
      #page(item)
      #scrap_products_links
    #end

    # собираем товары
    #@products_urls.each do |item|
      #page(item)
      #@all_products << ScrapProductInfo.scrap_product_info(@product_setting, @driver)
    #end

    #write_file
    #Connection.close_driver(@driver)

    # 2)Второй вариант
    # https://tdelics.ru

    # собираем товары из категории
    page(@scraping_pages[0])
    scrap_products_links_from_categories
    puts @products_urls

    # собираем инфу товара
    @products_urls.each do |item|
      page(item)
      sleep 2
      @all_products << ScrapProductInfo.scrap_product_info(@product_setting, @driver)
    end

    write_file
    Connection.close_driver(@driver)
  end

  def page(cur_page)
    # Посещаем страницу, открытую в браузере
    @driver.get cur_page
  end

  # собираем продкуты, если можно все их достать со страницы все товары
  def scrap_products_links
    return puts 'Товаров с таким селектом нет' unless @driver.find_element(:css, @product_css).displayed?

    puts 'Собираем продукты...'
    # Собираем все продукты
    html_products = @driver.find_elements(:css, @product_css)

    html_products.each do |html_product|
      url = html_product.find_element(:css, @product_link_css).attribute('href')
      @products_urls << url
    end
  end

  # Собираем товары из подкатегорий
  def scrap_products_links_from_categories
    puts 'Собираем продукты из подкатегорий...'
    categories = []
    categories << @driver.current_url

    collect_categories = lambda do
      return if categories.empty?

      cur_categories = []
      categories.each do |link|
        page(link)

        if @driver.find_elements(:css, '.subcollection-list .subcollection-list__item').length > 0
          html_categories = @driver.find_elements(:css, '.subcollection-list .subcollection-list__item')
          html_categories.each do |category|
            cur_category = category.attribute('href')
            cur_categories << cur_category
          end
        # Если на странице есть товары
        elsif @driver.find_elements(:css, '.product-preview').length > 0
          paginations_pages = ["#{@driver.current_url}?page=1"]
          html_products = @driver.find_elements(:css, '.product-preview')
          Pagination.pagination_pages(paginations_pages, @pagination_css, @driver)

          # Если есть пагинация
          if paginations_pages.length > 1
            paginations_pages.each_with_index do |cur_page, i|
              page(cur_page) if i > 0
              html_products = @driver.find_elements(:css, '.product-preview')
              html_products.each do |html_product|
                url = html_product.find_element(:css, '.product-preview__title a').attribute('href')
                @products_urls << url
              end
            end
          # Если нет пагинации
          else
            html_products.each do |html_product|
              url = html_product.find_element(:css, '.product-preview__title a').attribute('href')
              @products_urls << url
            end
          end
        end
        categories = cur_categories
      end

      collect_categories.call
    end

    collect_categories.call
  end

  protected

  def write_file
    puts 'Записываем в файл...'
    file_headers = []
    @all_products.each do |item|
      item.each { |key, _| file_headers << key unless file_headers.include? key }
    end

    CSV.open('products.csv', 'wb', write_headers: true, headers: file_headers) do |csv|
      @all_products.each do |product|
        csv << product
      end
    end
  end
end

test = CollectProducts.new
test.init
