module SSHKit
  module Interactive
    class Command
      attr_reader :host, :remote_command

      # remote_command can be an SSHKit::Command or a String
      def initialize(host, remote_command=nil)
        @host = host
        @remote_command = remote_command
      end

      def netssh_options
        self.host.netssh_options
      end

      def user
        self.host.user
      end

      def hostname
        self.host.hostname
      end

      def options
        opts = []
        opts << '-A' if netssh_options[:forward_agent]
        if netssh_options[:keys]
          netssh_options[:keys].each do |k|
            opts << "-i #{k}"
          end
        end
        opts << "-l #{user}" if user
        opts << %{-o "PreferredAuthentications #{netssh_options[:auth_methods].join(',')}"} if netssh_options[:auth_methods]
        opts << %{-o "ProxyCommand #{netssh_options[:proxy].command_line_template}"} if netssh_options[:proxy]
        opts << "-p #{netssh_options[:port]}" if netssh_options[:port]
        opts << '-t' if self.remote_command

        opts
      end

      def options_str
        self.options.join(' ')
      end

      def remote_command_str
        if self.remote_command
          cmd = []
          cmd << remote_pwd if !remote_pwd.empty?
          cmd << remote_env if !remote_env.empty?
          cmd << "#{self.remote_command}"
          %{"#{cmd.join(' ')}"}
        else
          ''
        end
      end

      def remote_pwd
        if self.remote_command.options[:in]
          "cd #{self.remote_command.options[:in]} &&"
        else
          ''
        end
      end

      def remote_env
        if self.remote_command.options[:env]
          env = self.remote_command.options[:env].map{|k, v| "#{k.upcase}=#{v}"}.join(' ')
        else
          ''
        end
      end

      def to_s
        parts = [
          'ssh',
          self.options_str,
          self.hostname,
          self.remote_command_str
        ]

        parts.reject(&:empty?).join(' ')
      end

      def execute
        system(self.to_s)
      end
    end
  end
end
