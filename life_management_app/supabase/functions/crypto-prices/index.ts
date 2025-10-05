import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const COINGECKO_API = 'https://api.coingecko.com/api/v3'

serve(async (req) => {
  try {
    const { symbols } = await req.json()
    
    if (!symbols || !Array.isArray(symbols)) {
      return new Response(
        JSON.stringify({ error: 'Invalid symbols parameter' }),
        { headers: { 'Content-Type': 'application/json' }, status: 400 }
      )
    }
    
    const ids = symbols.join(',')
    const response = await fetch(
      `${COINGECKO_API}/simple/price?ids=${ids}&vs_currencies=usd&include_24hr_change=true&include_market_cap=true`
    )
    
    const data = await response.json()
    
    return new Response(
      JSON.stringify({ success: true, data }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})
