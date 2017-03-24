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

The app provides us with two end points-
1. '/reports/influx'
2. '/reports/postgres'

Sending a get request to each end point will calculate and display its respective metrics.

The influxdb sample data points have a structure as follows:

```ruby
{
  series: "batchsize_#{batch_size}",
  values: {
    no_of_clicks: Random.rand(37...82),
  },
  tags: {
    region: 'us-west',
    name: 'My Website'
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

### Notes
- App does timeout occasionally.  Timeout coming from InfulxDB Ruby client.  Larger numbers timeout more frequently
- Batch numbers other than [1,10,100,1000] don't log correctly on server.
- If changing either batch size or test size please reset results databse.
