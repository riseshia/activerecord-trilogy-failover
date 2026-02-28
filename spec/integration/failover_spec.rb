# frozen_string_literal: true

require_relative "integration_helper"

RSpec.describe "Failover integration", skip: (!MYSQL_AVAILABLE && "MySQL not available") do
  metadata[:integration] = true

  it "INSERT and SELECT succeed when read_only is OFF" do
    conn_id_before = fetch_connection_id

    post = Post.create!(title: "hello")
    expect(Post.find(post.id).title).to eq("hello")

    conn_id_after = fetch_connection_id

    expect(conn_id_after).to eq(conn_id_before)
  end

  it "SELECT works but INSERT raises ConnectionFailed when read_only is ON" do
    Post.create!(title: "seed")

    conn_id_before = fetch_connection_id

    set_read_only!

    expect(Post.first.title).to eq("seed")

    expect {
      Post.create!(title: "should fail")
    }.to raise_error(ActiveRecord::ConnectionFailed)

    pool = ActiveRecord::Base.connection_pool
    expect(pool.connections).to be_empty

    unset_read_only!

    Post.create!(title: "on fresh connection")

    conn_id_after = fetch_connection_id

    expect(conn_id_after).not_to eq(conn_id_before)
  end
end
