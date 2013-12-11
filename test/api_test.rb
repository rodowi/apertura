require_relative './test_helper'

class ApiTest < Test::Unit::TestCase

  def app
    Sinatra::Application
  end

  def setup
    set_some_poll_options
    Answer.delete_all
    save_some_answers
  end

  def save_some_requests
    delete_some_user
    @requests = [
      { category: "Ed" },
      { category: "Ed" },
      { category: "Health" }
    ]
    @user = User.create(email: some_email, data_requests:@requests)

    early_email = some_email.insert(0, "early-")
    @early_adopter = User.find_by_email(early_email)
    @early_adopter.delete if @early_adopter
    @early_adopter = User.create(email: early_email, data_requests:[@requests[2]])
    @early_adopter.created_at = @early_adopter.created_at - 60 * 60 * 24
    @early_adopter.save
  end

  def select_option(id)
    option = Option.where(pseudo_uid: id).all.first
    SelectedOption.new(JSON.parse(option.to_json)).to_json
  end

  def save_some_answers
    5.times { Answer.create(selected_option: JSON.parse(select_option(1))) }
    2.times { Answer.create(selected_option: JSON.parse(select_option(100))) }
    3.times { Answer.create(selected_option: JSON.parse(select_option(101))) }
  end

  def test_it_returns_data_requests_by_category
    get '/votes.json'
    response = [
      {
        count: 5,
        category: "Lorem ipsum"
      }
    ]
    assert_equal response.to_json, last_response.body
  end

  def test_it_returns_dataset_results
    get '/answers/datasets.json'
    response = [
      {
        count: 3,
        dataset: Option.where(pseudo_uid: 101).all.first.text
      },
      {
        count: 2,
        dataset: Option.where(pseudo_uid: 100).all.first.text
      }
    ]
    assert_equal response.to_json, last_response.body
  end

  def test_it_returns_votes_per_day
    a = Answer.create(selected_option: JSON.parse(select_option(1)))
    a.created_at = Time.now - 1.day
    a.save
    response = [
      {
        count: 1,
        date: (Time.now.utc - 1.day).strftime("%Y-%m-%d")
      },
      {
        count: 5,
        date: Time.now.utc.strftime("%Y-%m-%d")
      }
    ]
    get '/answers/daily.json'
    assert_equal response.to_json, last_response.body
  end

  def test_it_returns_dump_of_chosen_categories
    t = Time.now.utc
    Answer.all.each do |a|
      a.created_at = t
      a.save
    end
    a = Answer.create(selected_option: JSON.parse(select_option(1)))
    a.created_at = t - 1.day
    a.save

    response = [
      { fecha: a.created_at, respuesta: "Lorem ipsum" }
    ]
    5.times { response << { fecha: t, respuesta: "Lorem ipsum" } }

    get '/answers/categories_dump.json'
    assert_equal response.to_json, last_response.body
  end

end

