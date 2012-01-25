#!/usr/bin/ruby -w

require "rubygems"
require "minitest/autorun"

require "zenweb/site"
require "test/helper"

class TestZenwebPage < MiniTest::Unit::TestCase
  include ChdirTest("example-site")

  attr_accessor :site, :page

  def setup
    super

    self.site = Zenweb::Site.new
    self.page = Zenweb::Page.new site, "blog/2012-01-02-page1.html.md"
  end

  def setup_deps
    Rake.application = Rake::Application.new
    site.scan

    assert_empty Rake.application.tasks

    p1 = site.pages["blog/2012-01-02-page1.html.md"]
    p2 = site.pages["blog/2012-01-03-page2.html.md"]

    return p1, p2
  end

  def test_body
    assert_equal "Not really much here to see.", page.body
  end

  def test_config
    exp = {"title" => "Example Page 1"}

    assert_kind_of Zenweb::Config, page.config
    assert_equal exp, page.config.h
  end

  def test_content
    assert_equal File.read(page.path), page.content
  end

  def test_date
    assert_equal Time.local(2012, 1, 2), page.date
  end

  def test_date_from_path
    assert_equal Time.local(2012, 1, 2), page.date_from_path
  end

  def test_depended_on_by
    p1, p2 = setup_deps

    p1.depended_on_by p2

    assert_tasks do
      assert_task p2.url_path, [p1.url_path]
    end
  end

  def test_depends_on
    p1, p2 = setup_deps

    p1.depends_on p2

    assert_tasks do
      assert_task p1.url_path, [p2.url_path]
    end
  end

  def test_filetype
    assert_equal "md", page.filetype
  end

  def test_filetypes
    assert_equal %w[md], page.filetypes
  end

  def test_filetypes_odd
    page = Zenweb::Page.new site, "blah.wtf"
    assert_equal %w[], page.filetypes
  end

  def test_generate
    page = Zenweb::Page.new site, "blah"

    def page.render
      "woot"
    end

    def page.open path, mode
      yield $stdout
    end

    out = "woot\n"
    err = "Rendering blah\n       to .site/blah\n"

    assert_output out, err do
      page.generate
    end
  end

  def test_generate_via_invoke
    Rake.application = Rake::Application.new
    site.scan
    site.wire
    self.page = site.pages["blog/2012-01-02-page1.html.md"]
    Rake.application[page.url_path].clear_prerequisites # no mkdir, thanks

    def page.generate
      raise "no generate"
    end

    e = assert_raises RuntimeError do
      Rake.application[page.url_path].invoke
    end

    assert_equal "no generate", e.message
  ensure
    FileUtils.rm_rf ".site"
  end

  def test_include
    # test via a layout page so we can test indirect access of page vars
    layout = Zenweb::Page.new(site, "_layouts/site.erb")
    fragment = layout.include("analytics.html.erb", page)
    assert_match(/UA-\d+/, site.config["google_ua"])
    assert_match site.config["google_ua"], fragment
  end

  def test_include_page_var
    # test via a layout page so we can test indirect access of page vars
    layout = Zenweb::Page.new(site, "_layouts/site.erb")
    fragment = layout.include("header.html.erb", page)
    assert_match "Example Page 1 ~ Example Website", fragment
  end

  def test_index
    assert_equal page.config["title"], page["title"]
  end

  def test_inspect
    assert_equal 'Page["blog/2012-01-02-page1.html.md"]', page.inspect
  end

  def test_layout
    assert_equal site.layout("post"), page.layout
  end

  def test_method_missing
    assert_equal page["title"], page.method_missing("title")
  end

  def test_method_missing_odd
    err = "Page[\"blog/2012-01-02-page1.html.md\"] does not define \"wtf\"\n"
    assert_output "", err do
      assert_nil page.method_missing("wtf")
    end
  end

  def test_method_missing_render
    err = "Page[\"blog/2012-01-02-page1.html.md\"] does not define wtf\n"
    assert_raises NoMethodError do
      assert_nil page.render_wtf
    end
  end

  def test_path
    assert_equal "blog/2012-01-02-page1.html.md", page.path
  end

  def test_render
    assert_equal "<p>Not really much here to see.</p>\n", page.render
  end

  def test_site
    assert_equal site, page.site
  end

  def test_subrender
    assert_equal "<p>Not really much here to see.</p>\n", page.subrender
  end

  def test_to_s
    assert_equal 'Page["blog/2012-01-02-page1.html.md"]', page.to_s
  end

  def test_url
    assert_equal "/blog/2012/01/02/page1.html", page.url

    page.config.h["date_fmt"] = "%Y/%m/"
    assert_equal "/blog/2012/01/page1.html", page.url

    page = Zenweb::Page.new site, "blog/blah.html"
    assert_equal "/blog/blah.html", page.url
  end

  def test_url_dir
    assert_equal ".site/blog/2012/01/02", page.url_dir
  end

  def test_url_path
    assert_equal ".site/blog/2012/01/02/page1.html", page.url_path
  end

  def test_wire
    Rake.application = Rake::Application.new
    site.scan
    self.page = site.pages["blog/2012-01-02-page1.html.md"]
    rake = Rake.application

    page.wire

    assert_tasks do
      # dirs
      assert_task ".site"
      assert_task ".site/blog"
      assert_task ".site/blog/2012"
      assert_task ".site/blog/2012/01"
      assert_task ".site/blog/2012/01/02"

      # aux
      assert_task "_layouts/post.erb", %w[_config.yml _layouts/site.erb]
      assert_task "_layouts/site.erb", %w[_config.yml]
      assert_task "blog/_config.yml", %w[_config.yml]
      assert_task "_config.yml"

      # page down to site
      assert_task page.path, %w[_layouts/post.erb blog/_config.yml]
      assert_task page.url_path, [page.url_dir, page.path]
      assert_task "site", [page.url_path], Rake::Task
    end
  end
end
