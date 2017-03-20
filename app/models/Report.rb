class Report

  # ReportHelpers:
  # contains methods that don't involve database operations
  include ReportHelpers

  def initialize(args)
    # @bm: name of testing database. Wiped with every run
    @bm = "benchmark"
    # @rp: name of report storage
    @rp = "reports"
    # @client: InfluxDB client
    @client = set_client
    # number of points to test with
    @num_test_points = args[:points]
    # different batch sizes to test
    @batch_sizes = args[:batch_sizes]
    # For server progress logs
    @init_time = Time.now
  end

  # #to_json:
  # runs all other methods and outputs a JSON friendly result array
  def to_json
    # #result_data runs all tests
    results = Hash[@batch_sizes.zip(result_data)]
    # delete testing database
    @client.delete_database(@bm)
    # reset @client database to persist results
    @client.config.database = @rp
    # saves results to database
    persist_results(results)
    # adds past averages to return object
    finalize_results(results)
  end

  private


  # #set_client:
  # ensures local database has proper setup for testing and storage
  def set_client
    client = InfluxDB::Client.new
    dbs = client.list_databases.to_json
    if dbs.include?(@bm) && dbs.include?(@rp)
      client.config.database = @bm
    elsif dbs.include?(@bm) && !dbs.include?(@rp)
      client.create_database(@rp)
      client.config.database = @bm
    elsif dbs.include?(@rp) && !dbs.include?(@bm)
      client.create_database(@bm)
      client.config.database = @bm
    else
      client.create_database(@rp)
      client.create_database(@bm)
      client.config.database = @bm
    end
    client
  end

  # #write_chunks:
  # iterates over dummy data and writes it to database
  def write_chunks(points)
    points.each_with_index do |point_group, index|
      check_progress(index, points.length, @init_time)
      @client.write_points(point_group)
    end
  end

  # #write_ones:
  # deals specifically with writing individual points
  def write_ones(points)
    points.flatten.each_with_index do |point, index|
      check_progress(index, @num_test_points, @init_time)
      @client.write_point("1", {
        values: point[:values],
        tags: point[:tags]
      })
    end
  end

  # #batch_result:
  # takes one batch size and writes points to database
  def batch_result(batch_size)
    puts "Starting Batch #{batch_size}"
    divider
    points = influx_test_points(batch_size, @num_test_points).to_a
    start_time = Time.now
    if batch_size == 1
      write_ones(points)
    else
      write_chunks(points)
    end
    write_duration = Time.now - start_time
    divider
    puts "Finsished Batch #{batch_size} in #{write_duration.round(3)} seconds"
    divider
    format_results({
      batch_size: batch_size,
      write_duration: write_duration,
      per_point_write: write_duration/@num_test_points,
    })
  end

  # #result_data:
  # maps @batch_sizes with #batch_result
  def result_data
    @batch_sizes.map do |batch_size|
      batch_result(batch_size)
    end
  end

  # #persist_results:
  # saves results of test to database
  def persist_results(results)
    @client.write_point("reports", {
      values: {
        json_results: results.to_json
      },
      timestamp: Time.now.to_i,
    })
  end

  # #finalize_results:
  # retrieves past results, averages, and appends to results
  def finalize_results(results)
    puts "compiling results..."
    past_results = @client.query 'SELECT * FROM "reports"'
    results[:past_averages_total_time_s] = parse_past_results(past_results)
    results[:total_test_time] = get_test_time(results, @batch_sizes)
    results[:test_details] = {
      num_test_points: @num_test_points,
      batch_sizes: @batch_sizes,
      test_database_name: @bm,
      report_database_name: @rp
    }
    results
  end

end
