class ReportsController < ApplicationController

  def influx
    @report = InfluxReport.new({
      points: 100000,
      batch_sizes: [1, 10 ,100, 1000],
    })
    render json: JSON.pretty_generate(@report.to_json)
  end

  def postgres
    @report = PostgresReport.new({
      points: 100000,
      batch_sizes: [1, 10 ,100, 1000],
    })
    render json: JSON.pretty_generate(@report.to_json)
  end

end
