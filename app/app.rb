class App
  attr_accessor :files

  DEFAULT_FILES_DIRECTORY = 'files/pages'.freeze

  def initialize(files_dir = nil)
    base_directory = files_dir || DEFAULT_FILES_DIRECTORY
    @files = Dir.glob("#{base_directory}/*.json")
  end

  def run_script
    files.each do |file|
      process_file(file)
    end
  end

  private

  def process_file(file)
    json_data = load_json(file)
    tables = extract_tables(json_data)

    tables.each_with_index do |table, index|
      table_values = extract_table_values(json_data, table)
      print_table(table['Page'], index + 1, tables.count, table_values)
    end
  end

  def load_json(file)
    JSON.parse(File.read(file))
  end

  def extract_tables(json_data)
    json_data.select { |block| block['BlockType'] == 'TABLE' }
  end

  def extract_table_values(json_data, table)
    table['Children'].map do |child_id|
      extract_row_values(json_data, child_id)
    end.compact
  end

  def extract_row_values(json_data, cell_id)
    cell = find_block_by_id(json_data, cell_id)
    row_index = cell['CellLocation']['R'] - 1

    cell_text = cell['Children'].map do |child_id|
      find_block_by_id(json_data, child_id)['Text']
    end.join(' ')

    { row_index: row_index, cell_text: cell_text }
  end

  def find_block_by_id(json_data, id)
    json_data.find { |block| block['Id'] == id }
  end

  def print_table(page, table_number, tables_count, table_values)
    puts "\n\n\n"
    puts "Page: #{page} -- Table: #{table_number} of #{tables_count}"

    table_by_row = table_values.group_by { |cell| cell[:row_index] }
    table_by_row.each_value do |row|
      formatted_row = row.map { |cell| format_cell(cell[:cell_text]) }.join(',')
      puts formatted_row
    end
  end

  def format_cell(cell_text)
    cell_text.include?(',') ? "\"#{cell_text}\"" : cell_text
  end
end