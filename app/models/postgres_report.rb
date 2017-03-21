class PostgresReport

  include ReportHelpers

  def initialize(args)
    # number of points to test with
    @num_test_points = args[:points]
    # different batch sizes to test
    @batch_sizes = args[:batch_sizes]
    # For server progress logs
    @init_time = Time.now
  end

  def test_points(batch_size, num_test_points)
    test_points = (1..num_test_points).map do |num|
      [
        Random.rand(37...82),
        Random.rand(0...31).to_f,
        'working',
        "sensor_#{num}",
        Time.now
      ]
    end
    test_points.each_slice(batch_size)
  end

  # #to_json:
  # outputs a JSON friendly result array
  def to_json
    # #result_data runs all tests
    results = finalize_results(Hash[@batch_sizes.zip(result_data)])
  end

  private

    # #write_ones:
    # deals specifically with writing individual points
    def write_ones(data)
      data.each_with_index do |datum, index|
        check_progress(index, @num_test_points, @init_time)
        Radiator.create(temp: datum[0], wspd: datum[1], status: datum[2], sensor: datum[3], timestamp: datum[5])
      end
    end

    # #write_chunks:
    # iterates over dummy data and writes it to database
    def write_chunks(data)
      data.each_with_index do |datum, index|
        check_progress(index, data.length, @init_time)
        Radiator.import([:temp, :wspd, :status, :sensor, :timestamp], datum)
      end
    end

    # #batch_result:
    # takes one batch size and writes points to database
    def batch_result(batch_size)
      puts "Starting Batch #{batch_size}"
      divider
      points = test_points(batch_size, @num_test_points).to_a
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

  def finalize_results(results)
    puts "compiling results..."
    results[:total_test_time] = get_test_time(results, @batch_sizes)
    results[:test_details] = {
      num_test_points: @num_test_points,
      batch_sizes: @batch_sizes,
    }
    results
  end


end
