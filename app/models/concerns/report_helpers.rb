module ReportHelpers
  extend ActiveSupport::Concern
  # #test_points:
  # creates array of data and slices to appropriate size
  def influx_test_points(batch_size, num_test_points)
    test_points = (1..num_test_points).map do |num|
      {
        series: "#{batch_size}",
        values: {
          temp: Random.rand(37...82),
          wspd: Random.rand(0...31).to_f,
          status: 'working',
        },
        tags: {
          sensor: "sensor_#{num}",
        }
      }
    end
    test_points.each_slice(batch_size)
  end

  # #format_results:
  # properly formats the results of testing
  def format_results(args)
    {
      "total_time_s" => args[:write_duration].round(3),
      "time_per_point_ms" => (args[:per_point_write] * 1000).round(3),
    }
  end

  # #parse_json:
  # strips wrapping and parses json from database
  def parse_json(pr)
    pr.map do |result_hash|
      JSON.parse(result_hash["json_results"].gsub(/\\/,''))
    end
  end

  # #sort_past_results:
  # sorts past results into desired structure
  def sort_past_results(pr)
    sorted = {
      "1" => [],
      "10" => [],
      "100" => [],
      "1000" => [],
    }
    parse_json(pr).each do |result_hash|
      result_hash.each do |chunk, data|
        sorted[chunk].push(data["total_time_s"])
      end
    end
    average_sorted(sorted)
  end

  # #average_sorted:
  # takes the sorted data and averages it
  def average_sorted(sorted)
    sorted.each do |chunk,total_times|
      num_reports = total_times.length
      sorted[chunk] = (total_times.reduce(:+)/num_reports).round(3)
    end
  end

  # #parse_past_results:
  # takes past results from database and averages them
  def parse_past_results(pr)
    past_results = pr[0]["values"]
    if past_results.length > 1
      total = 0
      sorted = sort_past_results(past_results)
      sorted.each do |batch_number, batch_time|
        total += batch_time
      end
      sorted[:total_in_s] = total.round(3)
      sorted
    else
      nil
    end
  end

  # #divider:
  # Helps format console results
  def divider
    puts "-------------------------------------"
  end

  # #get_test_time:
  # takes final report and gives total test time
  def get_test_time(report, batch_sizes)
    batch_times = batch_sizes.map do |batch_size|
      report[batch_size]["total_time_s"]
    end
    batch_times.reduce(:+).round(3)
  end

  # #generate_progress:
  # Makes array of 10% progress markers
  def generate_progress(array_length)
    Array.new(100) { |index| index * (array_length / 100) }
  end

  # #check_progress:
  # Checks progress of the writing
  def check_progress(index, array_length, init_time)
    now = Time.now
    progress = generate_progress(array_length)
    if progress.include?(index + 1)
      puts "  -- #{(((index + 1).to_f/array_length.to_f) * 100).to_i}% of batch complete. Total time elapsed #{(now - init_time).round(2)} s"
    end
  end

end
