# Пагинация страниц товаров
# Нужно в переборе поменять на свои значения страниц
module Pagination
    def self.pagination_pages(scraping_pages, pagination_css, driver)
        return unless driver.find_elements(:css, pagination_css).size() > 0

        puts 'Собираем линки страниц...'
        # находим элементы в пагинации из дерева
        paginations_links = driver.find_elements(:css, pagination_css)
        # находим максимальное количество страниц
        max_page = paginations_links.map { |a| a.text.gsub(/[^0-9,-]+/, '') }.max.to_i

        (2..max_page).each do |x|
            #scraping_pages.push(scraping_pages[0].gsub('1/', "#{x}/"))
            scraping_pages.push(scraping_pages[0].gsub('=1', "=#{x}"))
        end
    end
end