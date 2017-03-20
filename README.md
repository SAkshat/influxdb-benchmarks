# InfluxDB / Postgres Benchmarking Test

Install [Git](http://git-scm.com/), [RVM](https://rvm.io/), PostgreSQL, [InfluxDB](https://portal.influxdata.com/downloads#influxdb).

To run just:
```bash
$ git clone https://github.com/SAkshat/influxdb-benchmark.git
$ cd influxdb-benchmark/
$ bundle
$ rake db:create
$ rake db:migrate
$ bin/rails server
```

There are two end points '/reports/postgress' and '/reports/influx' you can hit for their respective metrics

The influxdb sample data points have a structure as follows:

```ruby
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
```

To simulate the same in postgres, a table has been created with the fields - temp, wspd, status, sensor and timestamp.

## Configuration

To change either the number of points to test or the different batch sizes to test you can set them in ./app/controllers/reports_controller.rb

```ruby
Examples:

@report = InfluxReport.new({
  points: 100000,
  batch_sizes: [1,10,100,1000]
})

@report = PostgresReport.new({
  points: 100000,
  batch_sizes: [100 ,1000, 10000]
})
```
