import os
import json
import re
import logging
from typing import Dict, Any, Optional
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

# Logger setup
logger = logging.getLogger(__name__)

# Initialize Gemini
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
else:
    logger.warning("GEMINI_API_KEY not found in environment variables. Running in Mock/Fallback-only mode.")

class AIService:
    @staticmethod
    def _fallback_parse_transaction(text: str) -> Dict[str, Any]:
        """
        Regex fallback to parse basic Indonesian transaction texts.
        Example: "Saya menjual 10 kopi" or "membeli 5 sabun seharga 5000"
        """
        text_lower = text.lower().strip()
        
        # Default empty extraction
        extracted = {
            "product": "barang",
            "qty": 1,
            "type": "income",
            "amount": 0.0,
            "description": text
        }
        
        # Try to find transaction type (income vs expense)
        if any(w in text_lower for w in ["beli", "pengeluaran", "bayar", "belanja", "gaji karyawan"]):
            extracted["type"] = "expense"
        else:
            extracted["type"] = "income"
            
        # Regex to match: [number] [word] or [word] [number]
        # Pattern 1: "[qty] [product_name]" e.g., "10 kopi", "5 sabun"
        match_qty_prod = re.search(r'(\d+)\s+([a-zA-Z\s]+)', text_lower)
        if match_qty_prod:
            qty_str, prod_str = match_qty_prod.groups()
            # clean up product string (remove keywords like "pcs", "rupiah", "ribu")
            prod_clean = re.sub(r'\b(pcs|buah|biji|kg|liter|rupiah|rp|ribu|harga)\b', '', prod_str).strip()
            if prod_clean:
                extracted["product"] = prod_clean
                extracted["qty"] = int(qty_str)
        else:
            # Pattern 2: "[product_name] [qty]" e.g., "kopi 10"
            match_prod_qty = re.search(r'([a-zA-Z\s]+)\s+(\d+)', text_lower)
            if match_prod_qty:
                prod_str, qty_str = match_prod_qty.groups()
                prod_clean = re.sub(r'\b(pcs|buah|biji|kg|liter|rupiah|rp|ribu|harga)\b', '', prod_str).strip()
                if prod_clean:
                    extracted["product"] = prod_clean
                    extracted["qty"] = int(qty_str)

        # Look for numbers that might indicate prices
        # Look for patterns like "rp 50000", "50000 rupiah", "50 ribu", "harga 10000"
        prices = re.findall(r'(?:rp\.?\s*|harga\s*|seharga\s*)?(\d+[\d\s\.]*)\s*(?:rupiah|ribu)?', text_lower)
        for p_str in prices:
            p_clean = p_str.replace(".", "").replace(" ", "").strip()
            if p_clean.isdigit():
                val = float(p_clean)
                # If the user says "50 ribu", it represents 50000
                if "ribu" in text_lower and val < 10000:
                    val *= 1000
                if val > 100:  # Simple threshold to avoid confusing quantity with price
                    extracted["amount"] = val
                    break
                    
        return extracted

    @classmethod
    def parse_transaction(cls, text: str, retries: int = 2) -> Dict[str, Any]:
        """
        Parses transactions from natural language text using Gemini API.
        Includes validations, retries, and regex fallbacks.
        """
        # Prompt for Gemini
        system_instruction = (
            "You are a transaction parser. Parse the user's natural language transaction text in Indonesian. "
            "Output JSON with ONLY the following keys:\n"
            "- 'product': Name of the product (string, lowercase, e.g. 'kopi')\n"
            "- 'qty': Quantity (integer)\n"
            "- 'type': Either 'income' or 'expense' (string)\n"
            "- 'amount': Estimated total amount of transaction in IDR if mentioned (float or null)\n"
            "- 'description': Short summary of transaction (string)\n\n"
            "Rules:\n"
            "1. Output valid JSON only. Do not enclose it in markdown blocks or write any explanation.\n"
            "2. If quantity is not specified, default to 1.\n"
            "3. If transaction type is income (e.g. 'menjual', 'laku', 'dapat uang'), set type to 'income'. "
            "If transaction type is expense (e.g. 'membeli', 'belanja', 'bayar listrik', 'beli bahan'), set type to 'expense'."
        )

        user_prompt = f"Text: \"{text}\""

        if not GEMINI_API_KEY:
            logger.info("No Gemini API key configured. Executing fallback.")
            return cls._fallback_parse_transaction(text)

        for attempt in range(retries + 1):
            try:
                model = genai.GenerativeModel("gemini-1.5-flash")
                response = model.generate_content(
                    f"{system_instruction}\n\n{user_prompt}",
                    generation_config={"response_mime_type": "application/json"}
                )
                
                # Parse JSON
                result_json = response.text.strip()
                # Clean up if markdown block wrapper is returned
                if result_json.startswith("```json"):
                    result_json = result_json[7:]
                if result_json.endswith("```"):
                    result_json = result_json[:-3]
                result_json = result_json.strip()

                parsed_data = json.loads(result_json)
                
                # Validation
                if "product" not in parsed_data or "qty" not in parsed_data:
                    raise ValueError("Missing 'product' or 'qty' keys in response.")
                
                # Check type validity
                if parsed_data.get("type") not in ["income", "expense"]:
                    parsed_data["type"] = "income"
                
                # Convert quantity to int
                try:
                    parsed_data["qty"] = int(parsed_data["qty"])
                except:
                    parsed_data["qty"] = 1
                    
                # Return validated data
                return parsed_data

            except Exception as e:
                logger.error(f"Error parsing transaction on attempt {attempt}: {str(e)}")
                if attempt == retries:
                    logger.info("All retries failed. Executing fallback.")
                    return cls._fallback_parse_transaction(text)

    @classmethod
    def generate_insight(cls, transactions_summary: str, products_list: str) -> str:
        """
        Generates business insights using Gemini.
        """
        if not GEMINI_API_KEY:
            return (
                "Insight AI (Fallback Mode):\n"
                "- Penjualan Anda berjalan dengan baik. Rekomendasi: Teruskan mencatat penjualan kopi dan sabun.\n"
                "- Pastikan stok produk terlaris Anda selalu terjaga agar pembeli tidak kecewa."
            )
            
        prompt = (
            f"Anda adalah konsultan bisnis UMKM di Indonesia. Berikan insight bisnis singkat, padat, dan "
            f"praktis berdasarkan data penjualan berikut:\n\n"
            f"Rangkuman Penjualan:\n{transactions_summary}\n\n"
            f"Daftar Produk:\n{products_list}\n\n"
            f"Berikan output dalam format poin-poin yang mudah dipahami oleh pemilik warung kecil/UMKM. "
            f"Gunakan bahasa Indonesia yang santun dan menyemangati."
        )
        
        try:
            model = genai.GenerativeModel("gemini-1.5-flash")
            response = model.generate_content(prompt)
            return response.text.strip()
        except Exception as e:
            logger.error(f"Error generating insight: {str(e)}")
            return (
                "Sistem sedang sibuk. Rekomendasi umum: Perhatikan produk dengan stok di bawah 5 pcs "
                "dan lakukan promosi di akhir pekan."
            )

    @classmethod
    def generate_marketing(cls, platform: str, topic: str, product_name: Optional[str] = None, tone: str = "friendly") -> str:
        """
        Generates marketing content (Instagram captions, WhatsApp stories, Marketplace description)
        """
        if not GEMINI_API_KEY:
            return (
                f"Konten Pemasaran ({platform}) - Topic: {topic}\n\n"
                f"Hai Kak! Yuk cobain {product_name or 'produk unggulan kami'}! "
                f"Sangat cocok untuk kebutuhan harian Anda. Hubungi kami sekarang ya! #UMKMIndonesia"
            )

        prompt = (
            f"Buatlah konten pemasaran dalam Bahasa Indonesia untuk platform: {platform}.\n"
            f"Topik/Tema: {topic}\n"
            f"Nama Produk: {product_name or 'Umum'}\n"
            f"Nada/Tone: {tone}\n\n"
            f"Format konten harus sesuai dengan karakteristik platform {platform}. "
            f"Sertakan hashtag yang relevan dan ajakan bertindak (Call to Action)."
        )

        try:
            model = genai.GenerativeModel("gemini-1.5-flash")
            response = model.generate_content(prompt)
            return response.text.strip()
        except Exception as e:
            logger.error(f"Error generating marketing content: {str(e)}")
            return f"Gagal membuat konten karena gangguan koneksi. Topik: {topic} untuk {platform}."
