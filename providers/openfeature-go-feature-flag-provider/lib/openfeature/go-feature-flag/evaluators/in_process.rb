# frozen_string_literal: true

require "wasmtime"

module OpenFeature
  module GoFeatureFlag
    module Evaluators
      class InProcess
        def initialize(api_client:)
          @api_client = api_client
          response = @api_client.fetch_flags_configuration
          @flags = response.flags
          @etag = response.etag
          @last_modified = response.last_modified

          engine = Wasmtime::Engine.new
          component = Wasmtime::Component::Component.from_file(engine, "wasm/eval.wasm")
          linker = Wasmtime::Component::Linker.new(engine)
          Wasmtime::WASI::P2.add_to_linker_sync(linker)

          wasi_config = Wasmtime::WasiConfig.new
                                            .inherit_stdout
                                            .inherit_stderr
                                            .set_argv(ARGV)
                                            .set_env(ENV)

          mod = Wasmtime::Module.from_file(engine, )
          store = Wasmtime::Store.new(engine)
          instace = Wasmtime::Instance.new(store, mod)
          @evaluate = instace.export("evaluate")
          @malloc = instace.export("malloc")
          @free = instace.export("free")
        end

        def evaluate(flag_key:, evaluation_context:)
          @evaluate.invoke(flag_key: flag_key, evaluation_context: evaluation_context)
        end
      end
    end
  end
end
