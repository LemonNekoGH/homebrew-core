class ApacheFlink < Formula
  desc "Scalable batch and stream data processing"
  homepage "https://flink.apache.org/"
  url "https://www.apache.org/dyn/closer.lua?path=flink/flink-1.17.0/flink-1.17.0-bin-scala_2.12.tgz"
  mirror "https://archive.apache.org/dist/flink/flink-1.17.0/flink-1.17.0-bin-scala_2.12.tgz"
  version "1.17.0"
  sha256 "c7ad0b93fc577fe22c83527acf9a80219dbf75b0e2ced3c8296add3c84e9dd38"
  license "Apache-2.0"
  head "https://github.com/apache/flink.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, all: "58c126b44a54c8bdcde585c115804c57991a0f43a362d5a7451a334c471bf640"
  end

  depends_on "openjdk@11"

  def install
    rm_f Dir["bin/*.bat"]
    libexec.install Dir["*"]
    (libexec/"bin").env_script_all_files(libexec/"libexec", Language::Java.java_home_env("11"))
    (libexec/"bin").install Dir["#{libexec}/libexec/*.jar"]
    chmod 0755, Dir["#{libexec}/bin/*"]
    bin.write_exec_script "#{libexec}/bin/flink"
  end

  test do
    (testpath/"log").mkpath
    (testpath/"input").write "foo bar foobar"
    expected = <<~EOS
      (foo,1)
      (bar,1)
      (foobar,1)
    EOS
    ENV.prepend "_JAVA_OPTIONS", "-Djava.io.tmpdir=#{testpath}"
    ENV.prepend "FLINK_LOG_DIR", testpath/"log"
    system libexec/"bin/start-cluster.sh"
    system bin/"flink", "run", "-p", "1",
           libexec/"examples/streaming/WordCount.jar", "--input", testpath/"input",
           "--output", testpath/"result"
    system libexec/"bin/stop-cluster.sh"
    assert_predicate testpath/"result", :exist?
    result_files = Dir[testpath/"result/*/*"]
    assert_equal 1, result_files.length
    assert_equal expected, (testpath/result_files.first).read
  end
end
