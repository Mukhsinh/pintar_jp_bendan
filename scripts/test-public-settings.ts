
import { createClient } from '@supabase/supabase-js'

const url = 'https://omlbijupllrglmebbqnn.supabase.co'
const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9tbGJpanVwbGxyZ2xtZWJicW5uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2OTIxMTEsImV4cCI6MjA4ODI2ODExMX0.rHTlmURvcVQh2WdMsGnEe0zTytY76iKwHAcx1iJudd8'

async function test() {
    const supabase = createClient(url, anonKey)
    const { data, error } = await supabase
        .from('t_settings')
        .select('key, value')
        .eq('key', 'company_info')
        .single()

    if (error) {
        console.error('Error:', error)
    } else {
        console.log('Data:', JSON.stringify(data, null, 2))
    }
}

test()
