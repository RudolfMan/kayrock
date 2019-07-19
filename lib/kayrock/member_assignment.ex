defmodule Kayrock.MemberAssignment do
  @moduledoc """
  Code to serialize/deserialize Kafka consumer group member assignments
  """

  defstruct version: 0, partition_assignments: [], user_data: ""

  defmodule PartitionAssignment do
    defstruct topic: nil, partitions: []
  end

  def deserialize(<<>>), do: %__MODULE__{}

  def deserialize(<<version::16-signed, assignments_size::32-signed, rest::binary>>) do
    {partition_assignments, user_data} = parse_assignments(assignments_size, rest, [])

    %__MODULE__{
      version: version,
      partition_assignments: partition_assignments,
      user_data: user_data
    }
  end

  defp parse_assignments(0, rest, assignments), do: {assignments, rest}

  defp parse_assignments(
         size,
         <<topic_len::16-signed, topic::size(topic_len)-binary, partition_len::32-signed,
           rest::binary>>,
         assignments
       ) do
    {partitions, rest} = parse_partitions(partition_len, rest, [])

    parse_assignments(size - 1, rest, [
      %PartitionAssignment{topic: topic, partitions: partitions} | assignments
    ])
  end

  defp parse_partitions(0, rest, partitions), do: {partitions, rest}

  defp parse_partitions(
         size,
         <<partition::32-signed, rest::binary>>,
         partitions
       ) do
    parse_partitions(size - 1, rest, [partition | partitions])
  end
end