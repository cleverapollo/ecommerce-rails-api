module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module DatabaseStatements

        # ЖЕСТКИЙ КОСТЫЛь!
        # Переопределяем метод вставки, чтобы убрать RETURNING для партицируемых таблиц
        def sql_for_insert(sql, pk, id_value, sequence_name, binds)
          table_ref = extract_table_ref_from_insert_sql(sql)

          # Только для таблиц с партицированием
          if ['"users"', '"sessions"'].include?(table_ref)
            return [sql, binds]
          end

          unless pk
            pk = primary_key(table_ref) if table_ref
          end

          if pk && use_insert_returning?
            sql = "#{sql} RETURNING #{quote_column_name(pk)}"
          end

          [sql, binds]
        end
      end
    end
  end
end
