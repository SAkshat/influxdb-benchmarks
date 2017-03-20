class Radiator < ActiveRecord::Base

  def self.test_points(batch_size, num_test_points)
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

  def self.write_ones(data)
    data.each do |datum|
      Radiator.create(temp: datum[0], wspd: datum[1], status: datum[2], sensor: datum[3], timestamp: datum[5])
    end
  end

  def self.write_chunks(data)
    data.each do |datum|
      Radiator.import([:temp, :wspd, :status, :sensor, :timestamp], datum)
    end
  end

  def self.write_data(num_test_points, batch_size=1)
    data = test_points(batch_size, num_test_points)

    start_time = Time.now
    if batch_size == 1
      write_ones(data)
    else
      write_chunks(data)
    end
    write_duration = Time.now - start_time
    puts "Finsished Batch #{batch_size} in #{write_duration.round(3)} seconds"
  end

end
