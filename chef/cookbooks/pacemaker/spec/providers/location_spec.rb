require 'chef/application'
require File.expand_path('../spec_helper', File.dirname(__FILE__))
require File.expand_path('../helpers/cib_object', File.dirname(__FILE__))
require File.expand_path('../fixtures/location_constraint', File.dirname(__FILE__))

describe "Chef::Provider::PacemakerLocation" do
  # for use inside examples:
  let(:fixture) { Chef::RSpec::Pacemaker::Config::LOCATION_CONSTRAINT.dup }
  # for use outside examples (e.g. when invoking shared_examples)
  fixture = Chef::RSpec::Pacemaker::Config::LOCATION_CONSTRAINT.dup

  before(:each) do
    runner_opts = {
      :step_into => ['pacemaker_location']
    }
    @chef_run = ::ChefSpec::Runner.new(runner_opts)
    @chef_run.converge "pacemaker::default"
    @node = @chef_run.node
    @run_context = @chef_run.run_context

    @resource = Chef::Resource::PacemakerLocation.new(fixture.name, @run_context)
    @resource.rsc   fixture.rsc
    @resource.score fixture.score
    @resource.node  fixture.node.dup
  end

  let (:provider) { Chef::Provider::PacemakerLocation.new(@resource, @run_context) }

  def cib_object_class
    Pacemaker::Constraint::Location
  end

  include Chef::RSpec::Pacemaker::CIBObject

  describe ":create action" do
    def test_modify(expected_cmds)
      yield

      stub_shellout(fixture.definition_string)

      provider.run_action :create

      expected_cmds.each do |cmd|
        expect(@chef_run).to run_execute(cmd)
      end
      expect(@resource).to be_updated
    end

    it "should modify the constraint if it has a different resource" do
      new_resource = 'group2'
      fixture.rsc = new_resource
      expected_configure_cmd_args = [fixture.reconfigure_command]
      test_modify(expected_configure_cmd_args) do
        @resource.rsc new_resource
      end
    end

    it "should modify the constraint if it has a different score" do
      new_score = '100'
      fixture.score = new_score
      expected_configure_cmd_args = [fixture.reconfigure_command]
      test_modify(expected_configure_cmd_args) do
        @resource.score new_score
      end
    end

    it "should modify the constraint if it has a different node" do
      new_node = 'node2'
      fixture.node = new_node
      expected_configure_cmd_args = [fixture.reconfigure_command]
      test_modify(expected_configure_cmd_args) do
        @resource.node new_node
      end
    end

  end

  describe ":delete action" do
    it_should_behave_like "action on non-existent resource", \
      :delete, "crm configure delete #{fixture.name}", nil
  end

end
