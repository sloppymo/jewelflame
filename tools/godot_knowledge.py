#!/usr/bin/env python3
"""
Godot Knowledge Base Query Tool for Jewelflame
Queries Supabase for development patterns and constraints.
"""

import os
import sys
from typing import List, Dict, Optional, Any

try:
    from supabase import create_client, Client
except ImportError:
    print("Installing supabase-py...")
    os.system("pip install supabase -q")
    from supabase import create_client, Client


class GodotKnowledge:
    """Client for querying Godot development knowledge from Supabase."""
    
    def __init__(self):
        # Default local Supabase credentials for Jewelflame
        self.url = os.getenv("SUPABASE_URL", "http://127.0.0.1:54331")
        self.key = os.getenv("SUPABASE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0")
        
        try:
            self.client: Client = create_client(self.url, self.key)
        except Exception as e:
            print(f"Warning: Could not connect to Supabase: {e}")
            print(f"Make sure Supabase is running: supabase start")
            self.client = None
    
    def is_connected(self) -> bool:
        """Check if Supabase connection is active."""
        return self.client is not None
    
    def find_similar_knowledge(self, query: str, limit: int = 3, threshold: float = 0.7) -> List[Dict[str, Any]]:
        """
        Find knowledge entries similar to the query.
        
        Args:
            query: Search query text
            limit: Maximum number of results
            threshold: Minimum similarity score (0.0-1.0)
            
        Returns:
            List of matching knowledge entries with similarity scores
        """
        if not self.client:
            print("Error: Not connected to Supabase")
            return []
        
        try:
            # Search in title, content, and tags
            # Use OR to match any field
            response = self.client.table("godot_knowledge")\
                .select("id, title, content, tags, knowledge_categories!inner(name)")\
                .or_(f"title.ilike.%{query}%,content.ilike.%{query}%,tags.cs.{{{query}}}")\
                .limit(limit * 2)\
                .execute()
            
            results = []
            for item in response.data:
                # Calculate simple text-based similarity
                similarity = self._calculate_similarity(query, item["content"])
                if similarity >= threshold:
                    results.append({
                        "id": item["id"],
                        "title": item["title"],
                        "content": item["content"],
                        "category": item["knowledge_categories"]["name"] if item.get("knowledge_categories") else "unknown",
                        "tags": item.get("tags", []),
                        "similarity": similarity
                    })
            
            # Sort by similarity and return top results
            results.sort(key=lambda x: x["similarity"], reverse=True)
            return results[:limit]
            
        except Exception as e:
            print(f"Error querying knowledge base: {e}")
            return []
    
    def get_by_category(self, category: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Get all knowledge entries in a specific category."""
        if not self.client:
            return []
        
        try:
            response = self.client.table("godot_knowledge")\
                .select("id, title, content, tags, knowledge_categories(name)")\
                .eq("knowledge_categories.name", category)\
                .limit(limit)\
                .execute()
            
            return response.data
        except Exception as e:
            print(f"Error: {e}")
            return []
    
    def get_hexforge_constraints(self) -> List[Dict[str, Any]]:
        """Get critical HexForge constraints (NEVER violate these)."""
        return self.find_similar_knowledge("constraint critical hexforge", limit=5)
    
    def get_pattern(self, pattern_name: str) -> Optional[Dict[str, Any]]:
        """Get a specific pattern by name."""
        if not self.client:
            return None
        
        try:
            response = self.client.table("godot_knowledge")\
                .select("*")\
                .eq("title", pattern_name)\
                .limit(1)\
                .execute()
            
            if response.data:
                return response.data[0]
            return None
        except Exception as e:
            print(f"Error: {e}")
            return None
    
    def _calculate_similarity(self, query: str, content: str) -> float:
        """Simple text similarity calculation."""
        query_lower = query.lower()
        content_lower = content.lower()
        
        # Count matching words
        query_words = set(query_lower.split())
        content_words = set(content_lower.split())
        
        if not query_words:
            return 0.0
        
        matches = len(query_words.intersection(content_words))
        return matches / len(query_words)
    
    def list_categories(self) -> List[str]:
        """List all available knowledge categories."""
        if not self.client:
            return []
        
        try:
            response = self.client.table("knowledge_categories")\
                .select("name")\
                .execute()
            
            return [item["name"] for item in response.data]
        except Exception as e:
            print(f"Error: {e}")
            return []


# Global instance for easy access
_knowledge_instance = None

def get_knowledge() -> GodotKnowledge:
    """Get or create the global knowledge instance."""
    global _knowledge_instance
    if _knowledge_instance is None:
        _knowledge_instance = GodotKnowledge()
    return _knowledge_instance


def main():
    """CLI interface for testing."""
    k = get_knowledge()
    
    if not k.is_connected():
        print("Failed to connect to Supabase")
        sys.exit(1)
    
    print("✅ Connected to Godot Knowledge Base")
    print(f"   URL: {k.url}")
    print()
    
    # List categories
    print("📚 Available Categories:")
    for cat in k.list_categories():
        print(f"   - {cat}")
    print()
    
    # Query example
    if len(sys.argv) > 1:
        query = " ".join(sys.argv[1:])
        print(f"🔍 Query: '{query}'")
        print()
        
        results = k.find_similar_knowledge(query, limit=3)
        
        if results:
            print(f"Found {len(results)} matches:")
            for r in results:
                print(f"\n  📖 {r['title']} (similarity: {r['similarity']:.2f})")
                print(f"     Category: {r['category']}")
                print(f"     Tags: {', '.join(r['tags'])}")
                print(f"     {r['content'][:200]}...")
        else:
            print("No matching knowledge found.")


if __name__ == "__main__":
    main()
