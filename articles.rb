require 'selenium-webdriver'
require 'down'
require 'fileutils'
require 'net/ftp'
require 'net/http'
require 'json'
require 'uri'
require './module/connection'

# Todo настроить пагинацию, добавить сопоставление статей дял получения сео линков

class CollectArticles
  # подключаем модули
  include Connection

  FTP_SERVER = 'ftp.f0797454.xsph.ru'
  FTP_LOGIN = 'f0797454'
  FTP_PASSWORD = 'f0797454'
  FTP_DIRECTORY = '/domains/f0797454.xsph.ru/public_html/images'
  USERNAME = '8280f888d13d0c44b7b325bb52de162d'
  PASSWORD = '7e8c6e13062de2f0b4e6da2b4421b676'
  DOMAIN = 'https://myshop-bmr840.myinsales.ru'

  def initialize
    @driver = Connection.set_driver
    @main_page = 'https://tdelics.ru/blogs/blog'
    @news_links = []
    @articles_url = 'https://myshop-bmr840.myinsales.ru/admin/blogs/1235161/articles.json'
    # селекторы css
    @articles_css = '.blog-list__item'
    @header_css = '.heading'
    @main_image_css = '.article-photo img'
    @content_css = '.article-content'
  end

  def init
    # Собираем линки
    page(@main_page)
    collect_news_links

    # Собираем Инфу статей
    @news_links.each do |link|
      puts link
      page(link)
      collect_article_info
    end
  end

  def page(cur_page)
    # Посещаем страницу, открытую в браузере
    @driver.get cur_page
  end

  def default_connection(cur_body, url)
    uri = URI.parse(url)
    header = { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' }
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(uri.path, header)
    request.basic_auth USERNAME, PASSWORD
    request.body = cur_body.to_json
    https.request(request)
  end

  def collect_news_links
    puts 'Собираем статьи...'
    articles = @driver.find_elements(:css, @articles_css)

    articles.each { |article| @news_links << article.find_element(:css, 'a').attribute('href') }
  end

  def collect_article_info
    header = @driver.find_element(:css, @header_css).text
    image = @driver.find_element(:css, @main_image_css).attribute('src')
    content = @driver.find_element(:css, @content_css)
    # так как на текущем доноре нет времени, берем текущее
    time = Time.new.strftime("%d.%m.%Y %H:%M")

    if content.find_elements(:css, 'img').size() > 0
      content.find_elements(:css, 'img').each do |item|
        url = item.attribute('src')
        # сохраняем изображение локально(на всякий)
        local_img = download_image(url)
        if local_img
          img_link_from_ftp = download_image_to_site(url)

          @driver.execute_script("arguments[0].setAttribute('src','#{img_link_from_ftp}')", item)
        end
      end
    end

    collect_donor_news = {
      "article": {
        "title": header,
        "content": content.attribute('innerHTML'),
        "published_at": time,
        "author": 'Администратор',
        'notice': content.attribute('innerHTML'),
        "image_attributes": {
          "src": image
        }
      }
    }

    default_connection(collect_donor_news, @articles_url)
  end

  # Сохраняем изображение локально
  def download_image(link)
    begin
      tempfile = Down.download(link)
      puts tempfile
      FileUtils.mv(tempfile.path, "./articles-images/#{tempfile.original_filename}")
      "./articles-images/#{tempfile.original_filename}"
    rescue Down::NotFound
      false
    end
  end
  
  # Загружаем изображение на сервер
  def download_ftp_image(cur_image)
    ftp = Net::FTP.new(FTP_SERVER)
    ftp.login(FTP_LOGIN, FTP_PASSWORD)
    ftp.chdir(FTP_DIRECTORY)
    ftp.putbinaryfile(cur_image)
    ftp.close
  end

  # Загружаем изображения из статей в файлы сайта
  def download_image_to_site(link)
    body = {
      'file':
        {
          'src': link
        }
    }
    data = default_connection(body, "#{DOMAIN}/admin/files.json")
    JSON.parse(data.body)['absolute_url']
  end
end

test = CollectArticles.new
test.init
