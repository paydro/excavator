require 'test_helper'

context "TableView" do
  include Excavator

  test "prints table title" do
    table_view = TableView.new do |t|
      t.title "Table View"
    end

    out, error = capture_io { puts table_view }
    assert_match /^Table View$/, out
  end

  test "prints out headers" do
    table_view = TableView.new do |t|
      t.header "header1"
      t.header "header2"
    end

    out, error = capture_io do
      puts table_view
    end

    assert_match /^header1 \| header2$/, out
  end

  test "prints data aligned to headers" do
    table_view = TableView.new do |t|
      t.header :name
      t.header :url

      t.record "Google", "http://www.google.com"
    end

    out, error = capture_io { puts table_view }
    lines = out.split("\n")

    assert_match /^name\s\s \| url\s{18}$/, lines[0]
    assert_match %r{Google \| http://www\.google\.com}, lines[1]
  end

  test "changing divider" do
    table_view = TableView.new do |t|
      t.header :name
      t.header :url
      t.divider "\t"
    end

    out, error = capture_io { puts table_view }
    assert_match /^name\turl$/, out
  end

  test "complains when adding a record with not enough values" do
    assert_raises TableView::InvalidDataForHeaders do
      table_view = TableView.new do |t|
        t.header :name
        t.record 1, 2
      end
    end
  end
end
