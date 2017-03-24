class Report

  def initialize(args)
    # @db: name of testing database. Wiped with every run
    @db = "benchmark"
    # number of points to test with
    @num_test_points = args[:points]
    # For server progress logs
    @init_time = Time.now
  end

  def seed_postgres
    Website.delete_all
    report = PostgresReport.new({ points: @num_test_points, batch_sizes: [1000] })
    report.to_json
  end

  def seed_influx
    @report = InfluxReport.new({
      points: @num_test_points,
      batch_sizes: [1000]
    })
    @report.to_json(false)
  end

  def clear_and_seed_data
    # puts seed_postgres
    puts seed_influx
  end

  def activerecord_metrics
    initial_time = Time.now.to_i
    Website.average(:no_of_clicks)
    final_time = Time.now.to_i

    { records_read: Website.count, time_taken: "#{final_time - initial_time} seconds" }
  end

  def postgres_direct_query_metrics
    initial_time = Time.now.to_i
    ActiveRecord::Base.connection.execute 'SELECT AVG(no_of_clicks) FROM websites'
    final_time = Time.now.to_i

    { records_read: Website.count, time_taken: "#{final_time - initial_time} seconds" }
  end

  def influx_metrics
    influx_client = InfluxDB::Client.new('benchmark')
    records_read = influx_client.query("SELECT count(no_of_clicks) FROM batchsize_1000")[0]["values"][0]["count"]
    initial_time = Time.now.to_i
    # batchsize_1000 - Series we seeded data into
    records = influx_client.query "SELECT MEAN(no_of_clicks) FROM batchsize_1000 WHERE TIME > 0 GROUP BY TIME(10m)"
    final_time = Time.now.to_i
    { records_read: records_read, time_taken: "#{final_time - initial_time} seconds" }
  end

  def calculate_metrics
    result = { }
    result[:activerecord] = activerecord_metrics
    result[:postgres_direct_query] = postgres_direct_query_metrics
    result[:influx_query] = influx_metrics
    result
  end

  def finalize_result(metrics)
    { 'Read Metrics': metrics }
  end

  def generate_read_metrics
    clear_and_seed_data
    metrics = calculate_metrics
    finalize_result(metrics)
  end


end
