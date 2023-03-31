# Модуль создания соединения
module Connection
	def self.set_driver
		puts 'Устанавливаем драйвер'

		linux_useragent = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.96 Safari/537.36'
		default_settings = 
		[
			'--headless=new',
			'--disable-blink-features=AutomationControlled',
			"user-agent=#{linux_useragent}", '--no-sandbox',
			'--disable-web-security', '--disable-xss-auditor',
			'excludeSwitches'
		]

		options = Selenium::WebDriver::Options.chrome(args: default_settings)

		# Инициализируем селениум драйвер
		service = Selenium::WebDriver::Service.chrome(path: './chromedriver')
		Selenium::WebDriver.for :chrome, options: options, service: service
	end

	def self.close_driver(driver)
		puts 'Удаляем драйвер'
		# Закрываем драйвер
		driver.quit
	end
end
