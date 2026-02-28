# frozen_string_literal: true

require_relative "integration_helper"

RSpec.describe "Failover integration", skip: (!MYSQL_AVAILABLE && "MySQL not available") do
  metadata[:integration] = true

  it "INSERT and SELECT succeed when read_only is OFF" do
    post = Post.create!(title: "hello")
    expect(Post.find(post.id).title).to eq("hello")
  end

  it "SELECT works but INSERT raises ConnectionFailed when read_only is ON" do
    Post.create!(title: "seed")

    admin = admin_connection
    admin.query("SET GLOBAL read_only = 1")
    admin.close

    expect(Post.first.title).to eq("seed")

    expect {
      Post.create!(title: "should fail")
    }.to raise_error(ActiveRecord::ConnectionFailed)
  end

  it "connection is discarded and replaced after ConnectionFailed" do
    Post.create!(title: "seed")

    conn_id_before = ActiveRecord::Base.lease_connection
      .raw_connection.query("SELECT CONNECTION_ID() AS id").first

    admin = admin_connection
    admin.query("SET GLOBAL read_only = 1")

    begin
      Post.create!(title: "should fail")
    rescue ActiveRecord::ConnectionFailed
      # expected
    end

    admin.query("SET GLOBAL read_only = 0")
    admin.close

    Post.create!(title: "on fresh connection")

    conn_id_after = ActiveRecord::Base.lease_connection
      .raw_connection.query("SELECT CONNECTION_ID() AS id").first

    expect(conn_id_after).not_to eq(conn_id_before)
  end
end
