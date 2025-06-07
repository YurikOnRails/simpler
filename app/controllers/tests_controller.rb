class TestsController < Simpler::Controller
  def index
    @time = Time.now
  end

  def plain
    render plain: 'Это простой текстовый ответ'
  end

  def json
    data = { message: 'Это JSON', time: Time.now }
    render json: data
  end

  def html
    render html: '<h1>Это HTML</h1>'
  end

  def xml
    data = { message: 'Это XML', time: Time.now }
    render xml: data
  end

  def show
    render plain: "Запрошен тест с ID: #{params[:id]}"
  end

  def custom_status
    status 201
    render plain: 'Создано успешно!'
  end
end
